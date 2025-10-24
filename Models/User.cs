using Cassandra.Mapping.Attributes;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace api_ride.Models
{
    [Table("users")]
    public class User
    {
        [PartitionKey]
        [Column("user_id")]
        public Guid UserId { get; set; }

        [Column("full_name")]
        public string FullName { get; set; } = string.Empty;

        [Column("phone_number")]
        public string Phone { get; set; } = string.Empty;

        [Column("email")]
        public string Email { get; set; } = string.Empty;

        [Column("password")]
        [JsonIgnore]
        public string Password { get; set; } = string.Empty;

        [Column("user_type")]
        public string Role { get; set; } = string.Empty;

        [Column("status")]
        public string Status { get; set; } = "active";

        [Column("created_at")]
        public DateTime CreatedAt { get; set; }

        [Column("updated_at")]
        public DateTime UpdatedAt { get; set; }
    }
}