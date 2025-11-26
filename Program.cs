using api_ride.Repositories;
using api_ride.Services;
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Text;
using FireSharp.Config;
using FireSharp.Interfaces;
using FireSharp;
var builder = WebApplication.CreateBuilder(args);


builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Encoder = System.Text.Encodings.Web.JavaScriptEncoder.Create(System.Text.Unicode.UnicodeRanges.All);
    });

// 2. Đăng ký Services
builder.Services.AddSingleton<ICassandraService, CassandraService>();
builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<FareCalculationService>();
builder.Services.AddScoped<IDriverService, DriverService>();
builder.Services.AddScoped<IRideRepository, RideRepository>();
builder.Services.AddScoped<IFirebaseService, FirebaseService>();
// 3. CẤU HÌNH JWT (BẮT BUỘC PHẢI CÓ NẾU DÙNG [AUTHORIZE])
var secretKey = builder.Configuration["Jwt:Secret"] ?? "YourVerySecureJwtSecretKeyThatIsAtLeast32CharactersLong!";
var keyBytes = Encoding.UTF8.GetBytes(secretKey);

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(keyBytes),
        ValidateIssuer = false,
        ValidateAudience = false,
        ClockSkew = TimeSpan.Zero
    };
});

// 4. Cấu hình Swagger để test được Token (Nút ổ khóa)
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "Ride API", Version = "v1" });

    // Thêm cấu hình nút Authorize trong Swagger
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "Nhập token vào đây: Bearer {token}",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            new string[] {}
        }
    });
});

// Add CORS (Cho phép Flutter gọi)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutter", policy =>
    {
        policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod();
    });
});
IFirebaseConfig config = new FirebaseConfig
{
    // 👇 Dán cái link mày vừa copy ở Bước 2 vào đây
    BasePath = "https://appride-f2bb5-default-rtdb.asia-southeast1.firebasedatabase.app",

    // 👇 Vào Firebase Console -> Project Settings -> Service Accounts -> Database Secrets -> Copy mã bí mật dán vào đây
    AuthSecret = "FYnQKi8Klx4Xcr7lKlg2cQVfPuv4c9pqtzZp3Hx4"
};

IFirebaseClient client = new FirebaseClient(config);

// Đăng ký Dependency Injection để dùng được ở chỗ khác
builder.Services.AddSingleton<IFirebaseClient>(client);
var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors("AllowFlutter");
app.UseAuthentication(); 
app.UseAuthorization();  

app.MapControllers();

app.Run();