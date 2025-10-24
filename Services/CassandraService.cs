using Cassandra;
using Cassandra.Mapping;
using api_ride.Models;
using CassandraSession = Cassandra.ISession;

namespace api_ride.Services
{
    public interface ICassandraService
    {
        Task<User?> GetUserByIdAsync(Guid userId);
        Task<User?> GetUserByEmailAsync(string email);
        Task<bool> CreateUserAsync(User user);
        Task<bool> UpdateUserAsync(User user);
        Task<bool> CreateRefreshTokenAsync(RefreshToken refreshToken);
        Task<RefreshToken?> GetRefreshTokenAsync(string token);
        Task<bool> RevokeRefreshTokenAsync(string token);
        Task<bool> RevokeAllUserRefreshTokensAsync(Guid userId);
    }

    public class CassandraService : ICassandraService, IDisposable
    {
        private readonly ICluster _cluster;
        private readonly CassandraSession _session;
        private readonly IMapper _mapper;
        private readonly ILogger<CassandraService> _logger;

        public CassandraService(IConfiguration configuration, ILogger<CassandraService> logger)
        {
            _logger = logger;
            
            var keyspace = configuration["Cassandra:Keyspace"] ?? "ride";
            var connectionString = configuration.GetConnectionString("Cassandra") ?? "127.0.0.1";
            var hosts = connectionString.Split(',');
            var port = configuration.GetValue<int>("Cassandra:Port", 9042);
            var username = configuration["Cassandra:Username"] ?? "cassandra";
            var password = configuration["Cassandra:Password"] ?? "cassandra";

            var builder = Cluster.Builder()
                .AddContactPoints(hosts)
                .WithPort(port)
                .WithCredentials(username, password);

            _cluster = builder.Build();
            _session = _cluster.Connect(keyspace);
            _mapper = new Mapper(_session);
            
            _logger.LogInformation("Connected to Cassandra successfully");
        }

        public async Task<User?> GetUserByIdAsync(Guid userId)
        {
            try
            {
                return await _mapper.FirstOrDefaultAsync<User>("SELECT * FROM users WHERE user_id = ?", userId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting user by ID");
                return null;
            }
        }

        public async Task<User?> GetUserByEmailAsync(string email)
        {
            try
            {
                // Direct CQL without mapper to avoid any mapping issues
                var cql = "SELECT user_id, full_name, phone_number, email, password, user_type, status, created_at, updated_at FROM users WHERE email = ? ALLOW FILTERING";
                var statement = await _session.PrepareAsync(cql);
                var result = await _session.ExecuteAsync(statement.Bind(email));
                var row = result.FirstOrDefault();
                
                if (row == null) return null;

                return new User
                {
                    UserId = row.GetValue<Guid>("user_id"),
                    FullName = row.GetValue<string>("full_name") ?? "",
                    Phone = row.GetValue<string>("phone_number") ?? "",
                    Email = row.GetValue<string>("email") ?? "",
                    Password = row.GetValue<string>("password") ?? "",
                    Role = row.GetValue<string>("user_type") ?? "",
                    Status = row.GetValue<string>("status") ?? "active",
                    CreatedAt = row.GetValue<DateTime>("created_at"),
                    UpdatedAt = row.GetValue<DateTime>("updated_at")
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting user by email: {Email}", email);
                return null;
            }
        }

        public async Task<bool> CreateUserAsync(User user)
        {
            try
            {
                if (user.UserId == Guid.Empty)
                    user.UserId = Guid.NewGuid();

                user.CreatedAt = DateTime.UtcNow;
                user.UpdatedAt = DateTime.UtcNow;

                // Direct CQL insert to avoid any mapping complexity
                var cql = "INSERT INTO users (user_id, full_name, phone_number, email, password, user_type, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
                var statement = await _session.PrepareAsync(cql);
                await _session.ExecuteAsync(statement.Bind(
                    user.UserId,
                    user.FullName,
                    user.Phone,
                    user.Email,
                    user.Password,
                    user.Role,
                    user.Status,
                    user.CreatedAt,
                    user.UpdatedAt
                ));

                _logger.LogInformation("User created: {UserId}", user.UserId);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating user");
                return false;
            }
        }

        public async Task<bool> UpdateUserAsync(User user)
        {
            try
            {
                user.UpdatedAt = DateTime.UtcNow;

                var cql = "UPDATE users SET full_name = ?, phone_number = ?, password = ?, user_type = ?, status = ?, updated_at = ? WHERE user_id = ?";
                var statement = await _session.PrepareAsync(cql);
                await _session.ExecuteAsync(statement.Bind(
                    user.FullName,
                    user.Phone,
                    user.Password,
                    user.Role,
                    user.Status,
                    user.UpdatedAt,
                    user.UserId
                ));

                _logger.LogInformation("User updated: {UserId}", user.UserId);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating user");
                return false;
            }
        }

        public async Task<bool> CreateRefreshTokenAsync(RefreshToken refreshToken)
        {
            try
            {
                var cql = "INSERT INTO refresh_tokens (\"token\", user_id, expires_at, created_at, is_revoked) VALUES (?, ?, ?, ?, ?)";
                var statement = await _session.PrepareAsync(cql);
                await _session.ExecuteAsync(statement.Bind(
                    refreshToken.Token,
                    refreshToken.UserId,
                    refreshToken.ExpiresAt,
                    refreshToken.CreatedAt,
                    refreshToken.IsRevoked
                ));
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating refresh token");
                return false;
            }
        }

        public async Task<RefreshToken?> GetRefreshTokenAsync(string token)
        {
            try
            {
                var cql = "SELECT \"token\", user_id, expires_at, created_at, is_revoked FROM refresh_tokens WHERE \"token\" = ?";
                var statement = await _session.PrepareAsync(cql);
                var result = await _session.ExecuteAsync(statement.Bind(token));
                var row = result.FirstOrDefault();
                
                if (row == null) return null;

                return new RefreshToken
                {
                    Token = row.GetValue<string>("token") ?? "",
                    UserId = row.GetValue<Guid>("user_id"),
                    ExpiresAt = row.GetValue<DateTime>("expires_at"),
                    CreatedAt = row.GetValue<DateTime>("created_at"),
                    IsRevoked = row.GetValue<bool>("is_revoked")
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting refresh token");
                return null;
            }
        }

        public async Task<bool> RevokeRefreshTokenAsync(string token)
        {
            try
            {
                var cql = "UPDATE refresh_tokens SET is_revoked = ? WHERE \"token\" = ?";
                var statement = await _session.PrepareAsync(cql);
                await _session.ExecuteAsync(statement.Bind(true, token));
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error revoking refresh token");
                return false;
            }
        }

        public async Task<bool> RevokeAllUserRefreshTokensAsync(Guid userId)
        {
            try
            {
                var cql = "UPDATE refresh_tokens SET is_revoked = ? WHERE user_id = ?";
                var statement = await _session.PrepareAsync(cql);
                await _session.ExecuteAsync(statement.Bind(true, userId));
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error revoking all user refresh tokens");
                return false;
            }
        }

        public void Dispose()
        {
            _session?.Dispose();
            _cluster?.Dispose();
        }
    }
}