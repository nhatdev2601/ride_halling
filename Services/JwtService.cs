using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using api_ride.Models;
using api_ride.Models.DTOs;

namespace api_ride.Services
{
    public interface IJwtService
    {
        string GenerateJwtToken(User user);
        string GenerateRefreshToken();
        ClaimsPrincipal? GetPrincipalFromExpiredToken(string token);
        Task<RefreshToken> CreateRefreshTokenAsync(Guid userId);
        Task<bool> ValidateRefreshTokenAsync(string token);
        Task<bool> RevokeRefreshTokenAsync(string token, string? replacedByToken = null);
    }

    public class JwtService : IJwtService
    {
        private readonly IConfiguration _configuration;
        private readonly ICassandraService _cassandraService;

        public JwtService(IConfiguration configuration, ICassandraService cassandraService)
        {
            _configuration = configuration;
            _cassandraService = cassandraService;
        }

        public string GenerateJwtToken(User user)
        {
            var jwtSettings = _configuration.GetSection("JwtSettings");
            var key = Encoding.ASCII.GetBytes(jwtSettings["Secret"] ?? throw new InvalidOperationException("JWT Secret not configured"));
            var issuer = jwtSettings["Issuer"];
            var audience = jwtSettings["Audience"];
            var expireMinutes = int.Parse(jwtSettings["ExpireMinutes"] ?? "60");

            var claims = new List<Claim>
            {
                new(ClaimTypes.NameIdentifier, user.UserId.ToString()),
                new(ClaimTypes.Email, user.Email),
                new(ClaimTypes.Name, user.FullName),
                new(ClaimTypes.Role, user.Role),
                new("phone", user.Phone),
                new("status", user.Status)
            };

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(claims),
                Expires = DateTime.UtcNow.AddMinutes(expireMinutes),
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature),
                Issuer = issuer,
                Audience = audience
            };

            var tokenHandler = new JwtSecurityTokenHandler();
            var token = tokenHandler.CreateToken(tokenDescriptor);
            return tokenHandler.WriteToken(token);
        }

        public string GenerateRefreshToken()
        {
            var randomNumber = new byte[64];
            using var rng = RandomNumberGenerator.Create();
            rng.GetBytes(randomNumber);
            return Convert.ToBase64String(randomNumber);
        }

        public ClaimsPrincipal? GetPrincipalFromExpiredToken(string token)
        {
            var jwtSettings = _configuration.GetSection("JwtSettings");
            var key = Encoding.ASCII.GetBytes(jwtSettings["Secret"] ?? throw new InvalidOperationException("JWT Secret not configured"));

            var tokenValidationParameters = new TokenValidationParameters
            {
                ValidateAudience = false,
                ValidateIssuer = false,
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(key),
                ValidateLifetime = false // We want to validate expired tokens
            };

            var tokenHandler = new JwtSecurityTokenHandler();
            var principal = tokenHandler.ValidateToken(token, tokenValidationParameters, out SecurityToken securityToken);
            
            if (securityToken is not JwtSecurityToken jwtSecurityToken || 
                !jwtSecurityToken.Header.Alg.Equals(SecurityAlgorithms.HmacSha256, StringComparison.InvariantCultureIgnoreCase))
            {
                throw new SecurityTokenException("Invalid token");
            }

            return principal;
        }

        public async Task<RefreshToken> CreateRefreshTokenAsync(Guid userId)
        {
            var refreshToken = new RefreshToken
            {
                Token = GenerateRefreshToken(),
                UserId = userId,
                ExpiresAt = DateTime.UtcNow.AddDays(7), // 7 days
                CreatedAt = DateTime.UtcNow,
                IsRevoked = false
            };

            await _cassandraService.CreateRefreshTokenAsync(refreshToken);
            return refreshToken;
        }

        public async Task<bool> ValidateRefreshTokenAsync(string token)
        {
            var refreshToken = await _cassandraService.GetRefreshTokenAsync(token);
            return refreshToken != null && refreshToken.IsActive;
        }

        public async Task<bool> RevokeRefreshTokenAsync(string token, string? replacedByToken = null)
        {
            try
            {
                return await _cassandraService.RevokeRefreshTokenAsync(token);
            }
            catch (Exception ex)
            {
                throw new Exception($"Error revoking refresh token: {ex.Message}", ex);
            }
        }
    }
}