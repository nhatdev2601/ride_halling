using Cassandra.Mapping.Attributes;

namespace api_ride.Models
{
    [Table("refresh_tokens")]
    public class RefreshToken
    {
        [PartitionKey]
        [Column("token")]
        public string Token { get; set; } = string.Empty;

        [Column("user_id")]
        public Guid UserId { get; set; }

        [Column("expires_at")]
        public DateTime ExpiresAt { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; }

        [Column("is_revoked")]
        public bool IsRevoked { get; set; }

        [Column("replaced_by_token")]
        public string? ReplacedByToken { get; set; }

        public bool IsExpired => DateTime.UtcNow >= ExpiresAt;
        public bool IsActive => !IsRevoked && !IsExpired;
    }
}