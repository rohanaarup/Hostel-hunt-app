import time
import requests
import json

# Wait 5 seconds for Django server to be ready
time.sleep(5)

BASE_URL = "http://localhost:8000/api"

# STEP 1: Dev-Verify OTP
print("=" * 40)
print("STEP 1: Dev-Verify OTP")
print("=" * 40)

step1_data = {"email": "testuser456@example.com"}
print("REQUEST JSON:")
print(json.dumps(step1_data, indent=2))
print()

try:
    response1 = requests.post(f"{BASE_URL}/otp/dev-verify/", json=step1_data)
    print(f"HTTP STATUS: {response1.status_code}")
    print()
    print("RESPONSE JSON:")
    print(json.dumps(response1.json(), indent=2))
except Exception as e:
    print(f"ERROR: {e}")

print("\n")

# STEP 2: Register new user
print("=" * 40)
print("STEP 2: Register new user")
print("=" * 40)

step2_data = {
    "full_name": "Test User",
    "email": "testuser456@example.com",
    "role": "student",
    "password": "TestPassword123!",
    "password_confirm": "TestPassword123!"
}
print("REQUEST JSON:")
print(json.dumps(step2_data, indent=2))
print()

try:
    response2 = requests.post(f"{BASE_URL}/auth/register/", json=step2_data)
    print(f"HTTP STATUS: {response2.status_code}")
    print()
    print("RESPONSE JSON:")
    print(json.dumps(response2.json(), indent=2))
except Exception as e:
    print(f"ERROR: {e}")

print("\n")

# STEP 3: Login
print("=" * 40)
print("STEP 3: Login")
print("=" * 40)

step3_data = {
    "email": "testuser456@example.com",
    "password": "TestPassword123!"
}
print("REQUEST JSON:")
print(json.dumps(step3_data, indent=2))
print()

try:
    response3 = requests.post(f"{BASE_URL}/auth/login/", json=step3_data)
    print(f"HTTP STATUS: {response3.status_code}")
    print()
    print("RESPONSE JSON:")
    print(json.dumps(response3.json(), indent=2))
except Exception as e:
    print(f"ERROR: {e}")
