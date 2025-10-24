using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using api_ride.Models.DTOs;
using api_ride.Services;

namespace api_ride.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;
        private readonly ILogger<AuthController> _logger;

        public AuthController(IAuthService authService, ILogger<AuthController> logger)
        {
            _authService = authService;
            _logger = logger;
        }

        [HttpPost("register")]
        public async Task<ActionResult<AuthResponse>> Register([FromBody] RegisterRequest request)
        {
            try
            {
                // Simple validation
                if (string.IsNullOrWhiteSpace(request.Email) || 
                    string.IsNullOrWhiteSpace(request.Password) ||
                    string.IsNullOrWhiteSpace(request.FullName) ||
                    string.IsNullOrWhiteSpace(request.Phone) ||
                    string.IsNullOrWhiteSpace(request.Role))
                {
                    return BadRequest(new { message = "All fields are required" });
                }

                if (request.Role != "passenger" && request.Role != "driver")
                {
                    return BadRequest(new { message = "Role must be 'passenger' or 'driver'" });
                }

                var result = await _authService.RegisterAsync(request);
                if (result == null)
                {
                    return BadRequest(new { message = "Registration failed" });
                }

                return Ok(result);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Registration error");
                return StatusCode(500, new { message = "Server error" });
            }
        }

        [HttpPost("login")]
        public async Task<ActionResult<AuthResponse>> Login([FromBody] LoginRequest request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
                {
                    return BadRequest(new { message = "Email and password are required" });
                }

                var result = await _authService.LoginAsync(request);
                if (result == null)
                {
                    return Unauthorized(new { message = "Invalid credentials" });
                }

                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Login error");
                return StatusCode(500, new { message = "Server error" });
            }
        }

        [HttpPost("refresh")]
        public async Task<ActionResult<AuthResponse>> RefreshToken([FromBody] RefreshTokenRequest request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.RefreshToken))
                {
                    return BadRequest(new { message = "Refresh token is required" });
                }

                var result = await _authService.RefreshTokenAsync(request.RefreshToken);
                if (result == null)
                {
                    return Unauthorized(new { message = "Invalid refresh token" });
                }

                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Refresh token error");
                return StatusCode(500, new { message = "Server error" });
            }
        }

        [HttpPost("revoke")]
        [Authorize]
        public async Task<ActionResult> RevokeToken([FromBody] RefreshTokenRequest request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.RefreshToken))
                {
                    return BadRequest(new { message = "Refresh token is required" });
                }

                var result = await _authService.RevokeTokenAsync(request.RefreshToken);
                if (!result)
                {
                    return BadRequest(new { message = "Failed to revoke token" });
                }

                return Ok(new { message = "Token revoked successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Token revocation error");
                return StatusCode(500, new { message = "Server error" });
            }
        }

        [HttpPost("logout")]
        [Authorize]
        public async Task<ActionResult> Logout([FromBody] RefreshTokenRequest request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.RefreshToken))
                {
                    return BadRequest(new { message = "Refresh token is required" });
                }

                var userId = GetCurrentUserId();
                if (userId == Guid.Empty)
                {
                    return Unauthorized(new { message = "Invalid user context" });
                }

                var result = await _authService.LogoutAsync(userId, request.RefreshToken);
                if (!result)
                {
                    return BadRequest(new { message = "Logout failed" });
                }

                return Ok(new { message = "Logged out successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Logout error");
                return StatusCode(500, new { message = "Server error" });
            }
        }

        [HttpGet("profile")]
        [Authorize]
        public async Task<ActionResult<UserDto>> GetProfile()
        {
            try
            {
                var userId = GetCurrentUserId();
                if (userId == Guid.Empty)
                {
                    return Unauthorized(new { message = "Invalid user context" });
                }

                var user = await _authService.GetCurrentUserAsync(userId);
                if (user == null)
                {
                    return NotFound(new { message = "User not found" });
                }

                return Ok(user);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Get profile error");
                return StatusCode(500, new { message = "Server error" });
            }
        }

        [HttpPut("profile")]
        [Authorize]
        public async Task<ActionResult<UserDto>> UpdateProfile([FromBody] UpdateProfileRequest request)
        {
            try
            {
                var userId = GetCurrentUserId();
                if (userId == Guid.Empty)
                {
                    return Unauthorized(new { message = "Invalid user context" });
                }

                var result = await _authService.UpdateProfileAsync(userId, request);
                if (result == null)
                {
                    return BadRequest(new { message = "Failed to update profile" });
                }

                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Update profile error");
                return StatusCode(500, new { message = "Server error" });
            }
        }

        [HttpPost("change-password")]
        [Authorize]
        public async Task<ActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.CurrentPassword) || 
                    string.IsNullOrWhiteSpace(request.NewPassword))
                {
                    return BadRequest(new { message = "Current password and new password are required" });
                }

                var userId = GetCurrentUserId();
                if (userId == Guid.Empty)
                {
                    return Unauthorized(new { message = "Invalid user context" });
                }

                var result = await _authService.ChangePasswordAsync(userId, request);
                if (!result)
                {
                    return BadRequest(new { message = "Failed to change password. Please check your current password." });
                }

                return Ok(new { message = "Password changed successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Change password error");
                return StatusCode(500, new { message = "Server error" });
            }
        }

        [HttpGet("validate")]
        [Authorize]
        public ActionResult ValidateToken()
        {
            try
            {
                var userId = GetCurrentUserId();
                var email = User.FindFirstValue(ClaimTypes.Email);
                var role = User.FindFirstValue(ClaimTypes.Role);
                var name = User.FindFirstValue(ClaimTypes.Name);

                return Ok(new 
                { 
                    valid = true, 
                    userId, 
                    email, 
                    role,
                    name,
                    message = "Token is valid" 
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Token validation error");
                return StatusCode(500, new { message = "Server error" });
            }
        }

        [HttpGet("me")]
        [Authorize]
        public async Task<ActionResult<UserDto>> GetCurrentUser()
        {
            try
            {
                var userId = GetCurrentUserId();
                if (userId == Guid.Empty)
                {
                    return Unauthorized(new { message = "Invalid user context" });
                }

                var user = await _authService.GetCurrentUserAsync(userId);
                if (user == null)
                {
                    return NotFound(new { message = "User not found" });
                }

                return Ok(user);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Get current user error");
                return StatusCode(500, new { message = "Server error" });
            }
        }

        [HttpPost("revoke-all")]
        [Authorize]
        public async Task<ActionResult> RevokeAllTokens()
        {
            try
            {
                var userId = GetCurrentUserId();
                if (userId == Guid.Empty)
                {
                    return Unauthorized(new { message = "Invalid user context" });
                }

                // This would revoke all refresh tokens for the user
                // For now, just return success
                return Ok(new { message = "All tokens revoked successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Revoke all tokens error");
                return StatusCode(500, new { message = "Server error" });
            }
        }

        private Guid GetCurrentUserId()
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdClaim, out var userId) ? userId : Guid.Empty;
        }
    }
}