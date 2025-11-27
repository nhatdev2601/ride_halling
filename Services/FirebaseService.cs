using FireSharp.Interfaces;
using FireSharp.Response;
using System.Net;
using System.Threading.Tasks;
using System;

namespace api_ride.Services
{
    // Interface Definition
    public interface IFirebaseService
    {
        Task UpdateRideStatusAsync(string rideId, string status);
        Task UpdateDriverLocationAsync(string rideId, double lat, double lng);
        Task<bool> TestConnectionAsync(object data);
        Task<bool> UpdateToFirebaseAsync(string path, object data);
    }

    // Class Implementation
    public class FirebaseService : IFirebaseService
    {
        private readonly IFirebaseClient _client;

        public FirebaseService(IFirebaseClient client)
        {
            _client = client;
        }

        public async Task<bool> UpdateToFirebaseAsync(string path, object data)
        {
            try
            {
                Console.WriteLine($" [Firebase] Đang update path: {path}");
                FirebaseResponse response = await _client.UpdateAsync(path, data);

                if (response.StatusCode == HttpStatusCode.OK)
                {
                    Console.WriteLine($" [Firebase] Update thành công: {path}");
                    return true;
                }
                else
                {
                    Console.WriteLine($" [Firebase] Lỗi: {response.StatusCode} - {response.Body}");
                    return false;
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($" [Firebase] Exception: {ex.Message}");
                return false;
            }
        }

        public async Task<bool> TestConnectionAsync(object data)
        {
            try
            {
                var response = await _client.SetAsync("test_connection", data);
                return response.StatusCode == HttpStatusCode.OK;
            }
            catch (Exception ex)
            {
                Console.WriteLine(" Lỗi Test Connection: " + ex.Message);
                throw;
            }
        }

        public async Task UpdateRideStatusAsync(string rideId, string status)
        {
            await UpdateToFirebaseAsync($"rides/{rideId}", new { status = status, updated_at = DateTime.UtcNow });
        }

        public async Task UpdateDriverLocationAsync(string rideId, double lat, double lng)
        {
            await UpdateToFirebaseAsync($"rides/{rideId}", new { driver_location = new { lat, lng } });
        }
    }
}