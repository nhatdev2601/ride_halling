using BCrypt.Net;
using api_ride.Models;
using api_ride.Models.DTOs;
using System.Security.Claims;

namespace api_ride.Services
{
    public interface IAuthService
    {
        Task<AuthResponse?> LoginAsync(LoginRequest request);
        Task<AuthResponse?> RegisterAsync(RegisterRequest request);
        Task<AuthResponse?> RefreshTokenAsync(string refreshToken);
        Task<bool> RevokeTokenAsync(string refreshToken);
        Task<bool> LogoutAsync(Guid userId, string refreshToken);
        Task<bool> ChangePasswordAsync(Guid userId, ChangePasswordRequest request);
        Task<UserDto?> GetCurrentUserAsync(Guid userId);
        Task<UserDto?> UpdateProfileAsync(Guid userId, UpdateProfileRequest request);
    }

    public class AuthService : IAuthService
    {
        private readonly ICassandraService _cassandraService;
        private readonly IJwtService _jwtService;
        private readonly ILogger<AuthService> _logger;

        public AuthService(ICassandraService cassandraService, IJwtService jwtService, ILogger<AuthService> logger)
        {
            _cassandraService = cassandraService;
            _jwtService = jwtService;
            _logger = logger;
        }

        public async Task<AuthResponse?> LoginAsync(LoginRequest request)
        {
            try
            {
                // Get user by email
                var user = await _cassandraService.GetUserByEmailAsync(request.Email);
                if (user == null || user.Status != "active")
                {
                    return null;
                }

                // Verify password
                if (!BCrypt.Net.BCrypt.Verify(request.Password, user.Password))
                {
                    return null;
                }

                // Generate tokens
                var jwtToken = _jwtService.GenerateJwtToken(user);
                var refreshToken = await _jwtService.CreateRefreshTokenAsync(user.UserId);

                return new AuthResponse
                {
                    Token = jwtToken,
                    RefreshToken = refreshToken.Token,
                    Expires = DateTime.UtcNow.AddMinutes(60), // Should match JWT expiration
                    User = MapToUserDto(user)
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during login for email: {Email}", request.Email);
                return null;
            }
        }

        public async Task<AuthResponse?> RegisterAsync(RegisterRequest request)
        {
            try
            {
                // Check if user already exists
                var existingUser = await _cassandraService.GetUserByEmailAsync(request.Email);
                if (existingUser != null)
                {
                    throw new InvalidOperationException("User with this email already exists");
                }

                // Validate role
                if (request.Role != "passenger" && request.Role != "driver")
                {
                    throw new InvalidOperationException("Role must be either 'passenger' or 'driver'");
                }

                // Create new user
                var user = new User
                {
                    UserId = Guid.NewGuid(),
                    FullName = request.FullName,
                    Phone = request.Phone,
                    Email = request.Email,
                    Password = BCrypt.Net.BCrypt.HashPassword(request.Password),
                    Role = request.Role,
                    Status = "active",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                var created = await _cassandraService.CreateUserAsync(user);
                if (!created)
                {
                    throw new InvalidOperationException("Failed to create user");
                }

                _logger.LogInformation("User registered successfully: {Email}", request.Email);

                // Generate tokens
                var jwtToken = _jwtService.GenerateJwtToken(user);
                var refreshToken = await _jwtService.CreateRefreshTokenAsync(user.UserId);

                return new AuthResponse
                {
                    Token = jwtToken,
                    RefreshToken = refreshToken.Token,
                    Expires = DateTime.UtcNow.AddMinutes(60),
                    User = MapToUserDto(user)
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during registration for email: {Email}", request.Email);
                throw;
            }
        }

        public async Task<AuthResponse?> RefreshTokenAsync(string refreshToken)
        {
            try
            {
                var storedRefreshToken = await _cassandraService.GetRefreshTokenAsync(refreshToken);
                if (storedRefreshToken == null || storedRefreshToken.IsRevoked || storedRefreshToken.ExpiresAt <= DateTime.UtcNow)
                {
                    return null;
                }

                var user = await _cassandraService.GetUserByIdAsync(storedRefreshToken.UserId);
                if (user == null || user.Status != "active")
                {
                    return null;
                }

                // Revoke the old refresh token
                await _cassandraService.RevokeRefreshTokenAsync(refreshToken);

                // Generate new tokens
                var jwtToken = _jwtService.GenerateJwtToken(user);
                var newRefreshToken = await _jwtService.CreateRefreshTokenAsync(user.UserId);

                return new AuthResponse
                {
                    Token = jwtToken,
                    RefreshToken = newRefreshToken.Token,
                    Expires = DateTime.UtcNow.AddMinutes(60),
                    User = MapToUserDto(user)
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during token refresh");
                return null;
            }
        }

        public async Task<bool> RevokeTokenAsync(string refreshToken)
        {
            try
            {
                return await _cassandraService.RevokeRefreshTokenAsync(refreshToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error revoking token");
                return false;
            }
        }

        public async Task<bool> LogoutAsync(Guid userId, string refreshToken)
        {
            try
            {
                // Revoke the specific refresh token
                await _cassandraService.RevokeRefreshTokenAsync(refreshToken);
                
                // Optionally revoke all user's refresh tokens for complete logout
                // await _cassandraService.RevokeAllUserRefreshTokensAsync(userId);
                
                _logger.LogInformation("User {UserId} logged out successfully", userId);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during logout for user: {UserId}", userId);
                return false;
            }
        }

        public async Task<bool> ChangePasswordAsync(Guid userId, ChangePasswordRequest request)
        {
            try
            {
                var user = await _cassandraService.GetUserByIdAsync(userId);
                if (user == null)
                {
                    return false;
                }

                // Verify current password
                if (!BCrypt.Net.BCrypt.Verify(request.CurrentPassword, user.Password))
                {
                    return false;
                }

                // Update password
                user.Password = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
                user.UpdatedAt = DateTime.UtcNow;

                return await _cassandraService.UpdateUserAsync(user);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error changing password for user: {UserId}", userId);
                return false;
            }
        }

        public async Task<UserDto?> GetCurrentUserAsync(Guid userId)
        {
            try
            {
                var user = await _cassandraService.GetUserByIdAsync(userId);
                return user != null ? MapToUserDto(user) : null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting current user: {UserId}", userId);
                return null;
            }
        }

        public async Task<UserDto?> UpdateProfileAsync(Guid userId, UpdateProfileRequest request)
        {
            try
            {
                var user = await _cassandraService.GetUserByIdAsync(userId);
                if (user == null)
                {
                    return null;
                }

                // Update fields if provided
                if (!string.IsNullOrWhiteSpace(request.FullName))
                {
                    user.FullName = request.FullName;
                }

                if (!string.IsNullOrWhiteSpace(request.Phone))
                {
                    user.Phone = request.Phone;
                }

                user.UpdatedAt = DateTime.UtcNow;

                var updated = await _cassandraService.UpdateUserAsync(user);
                if (!updated)
                {
                    return null;
                }

                return MapToUserDto(user);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating profile for user: {UserId}", userId);
                return null;
            }
        }

        private static UserDto MapToUserDto(User user)
        {
            return new UserDto
            {
                UserId = user.UserId,
                FullName = user.FullName,
                Phone = user.Phone,
                Email = user.Email,
                Role = user.Role,
                CreatedAt = user.CreatedAt
            };
        }
    }
}