-- 서비스별 데이터베이스 생성
CREATE DATABASE user_db;
CREATE DATABASE company_db;
CREATE DATABASE product_db;
CREATE DATABASE cart_db;
CREATE DATABASE order_db;
CREATE DATABASE payment_db;
CREATE DATABASE shipment_db;
CREATE DATABASE notification_db;
CREATE DATABASE review_db;
CREATE DATABASE customer_db;

-- 서비스별 전용 계정 생성
CREATE USER user_svc_user WITH PASSWORD '1234';
CREATE USER company_user WITH PASSWORD '1234';
CREATE USER product_user WITH PASSWORD '1234';
CREATE USER cart_user WITH PASSWORD '1234';
CREATE USER order_user WITH PASSWORD '1234';
CREATE USER payment_user WITH PASSWORD '1234';
CREATE USER shipment_user WITH PASSWORD '1234';
CREATE USER notification_user WITH PASSWORD '1234';
CREATE USER review_user WITH PASSWORD '1234';
CREATE USER customer_user WITH PASSWORD '1234';

-- 전용 계정에 해당 DB 권한 부여
GRANT ALL PRIVILEGES ON DATABASE user_db TO user_svc_user;
GRANT ALL PRIVILEGES ON DATABASE company_db TO company_user;
GRANT ALL PRIVILEGES ON DATABASE product_db TO product_user;
GRANT ALL PRIVILEGES ON DATABASE cart_db TO cart_user;
GRANT ALL PRIVILEGES ON DATABASE order_db TO order_user;
GRANT ALL PRIVILEGES ON DATABASE payment_db TO payment_user;
GRANT ALL PRIVILEGES ON DATABASE shipment_db TO shipment_user;
GRANT ALL PRIVILEGES ON DATABASE notification_db TO notification_user;
GRANT ALL PRIVILEGES ON DATABASE review_db TO review_user;
GRANT ALL PRIVILEGES ON DATABASE customer_db TO customer_user;
