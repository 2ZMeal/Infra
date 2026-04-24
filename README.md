# Infra

도시락 커머스 플랫폼 로컬 개발 환경 구성 저장소입니다.

---

## 사전 요구사항

**macOS / Windows / Linux 공통**
- Docker Desktop 설치 및 실행 중

---

## 최초 세팅 (처음 1회만)

### 1. 환경변수 파일 생성

```bash
cp .env.example .env
```

> `.env` 파일은 Git에 포함되지 않습니다. 각자 로컬에서 생성해야 합니다.

### 2. 이미지 빌드 + 전체 기동

```bash
docker compose -f docker-compose.dev.yml --profile infra --profile platform up -d --build
```

Config Server, Eureka Server, API Gateway 소스를 Docker 내부에서 Gradle로 빌드한 뒤 모든 컨테이너를 기동합니다.

---

## 매일 개발 시작

```bash
docker compose -f docker-compose.dev.yml --profile infra --profile platform up -d
```

infra(DB/Kafka) + Config Server + Eureka Server + API Gateway를 모두 기동합니다.

---

## 서비스 로컬 실행 가이드 (IntelliJ)

위 명령어로 infra + platform 기동 후 본인 서비스를 IntelliJ에서 실행합니다.

### Environment Variables 설정

`Edit Configurations... → Environment variables` 에 아래 값을 입력합니다.

```
SPRING_CLOUD_CONFIG_URI=http://localhost:8888;EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://localhost:8761/eureka;SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/{service}_db;SPRING_KAFKA_BOOTSTRAP_SERVERS=localhost:9092;EUREKA_INSTANCE_HOSTNAME=host.docker.internal
```

`{service}_db` 는 아래 표를 참고해 본인 서비스에 맞게 변경하세요.

> **EUREKA_INSTANCE_HOSTNAME=host.docker.internal** 설명
>
> Docker 컨테이너(Gateway)가 IntelliJ에서 실행 중인 로컬 서비스에 접근하기 위해 필요합니다.
> 이 값을 설정하면 서비스가 Eureka에 `host.docker.internal:{port}` 로 등록되어
> Gateway가 컨테이너 밖(맥북)의 서비스를 정상적으로 찾을 수 있습니다.
> 추후 전체 Docker 배포 시에는 이 값을 제거합니다.

| 서비스 | SPRING_DATASOURCE_URL | 포트 |
|---|---|---|
| user-service | `jdbc:postgresql://localhost:5432/user_db` | 19081 |
| company-service | `jdbc:postgresql://localhost:5432/company_db` | 19082 |
| product-service | `jdbc:postgresql://localhost:5432/product_db` | 19083 |
| cart-service | `jdbc:postgresql://localhost:5432/cart_db` | 19084 |
| order-service | `jdbc:postgresql://localhost:5432/order_db` | 19085 |
| payment-service | `jdbc:postgresql://localhost:5432/payment_db` | 19086 |
| shipment-service | `jdbc:postgresql://localhost:5432/shipment_db` | 19087 |
| notification-service | `jdbc:postgresql://localhost:5432/notification_db` | 19088 |
| review-service | `jdbc:postgresql://localhost:5432/review_db` | 19089 |
| customer-service | `jdbc:postgresql://localhost:5432/customer_db` | 19090 |

### 실행 후 확인

```bash
# Config + DB 연결 확인
curl -s http://localhost:{포트}/actuator/health

# Eureka 등록 확인
curl -s http://localhost:8761/eureka/apps/{SERVICE-NAME} | grep -o '<status>[^<]*</status>'
```

---

## 접속 주소

| 서비스 | 주소 |
|---|---|
| API Gateway | http://localhost:8080 |
| Kafdrop (Kafka UI) | http://localhost:9000 |
| Config Server | http://localhost:8888 |
| Eureka Server | http://localhost:8761 |
| Keycloak | http://localhost:8180 |

---

## 서비스별 DB 접속 정보

| 서비스 | DB | 계정 |
|---|---|---|
| user-service | `user_db` | `user_svc_user` |
| company-service | `company_db` | `company_user` |
| product-service | `product_db` | `product_user` |
| cart-service | `cart_db` | `cart_user` |
| order-service | `order_db` | `order_user` |
| payment-service | `payment_db` | `payment_user` |
| shipment-service | `shipment_db` | `shipment_user` |
| notification-service | `notification_db` | `notification_user` |
| review-service | `review_db` | `review_user` |
| customer-service | `customer_db` | `customer_user` |

> 비밀번호 기본값: `1234`

---

## 명령어 요약

| 명령어 | 설명 |
|---|---|
| `docker compose -f docker-compose.dev.yml --profile infra --profile platform up -d --build` | 최초 1회 — 이미지 빌드 + 전체 기동 |
| `docker compose -f docker-compose.dev.yml --profile infra --profile platform up -d` | 매일 시작 — infra + Config Server + Eureka + Gateway 기동 |
| `docker compose -f docker-compose.dev.yml --profile infra up -d` | infra만 기동 (IntelliJ로 서비스 개발 시) |
| `docker compose -f docker-compose.dev.yml --profile platform build` | Config/Eureka/Gateway 코드 변경 후 이미지 재빌드 |
| `docker compose -f docker-compose.dev.yml --profile platform build --no-cache` | 캐시 무시 강제 재빌드 |
| `docker compose -f docker-compose.dev.yml --profile infra --profile platform down` | infra + platform 종료 |
| `docker compose -f docker-compose.dev.yml --profile infra --profile platform --profile app --profile monitoring down` | 전체 종료 |
| `docker compose -f docker-compose.dev.yml --profile infra --profile platform ps` | 컨테이너 상태 확인 |
| `docker compose -f docker-compose.dev.yml --profile infra --profile platform logs -f` | 실시간 로그 |

---

## 자주 발생하는 문제

**컨테이너 이름 충돌**
```
The container name "/postgres" is already in use
```
```bash
docker rm -f postgres redis zookeeper kafka kafdrop keycloak
docker compose -f docker-compose.dev.yml --profile infra --profile platform up -d
```

**PostgreSQL DB 10개가 생성되지 않은 경우**

볼륨이 이미 존재하면 초기화 스크립트가 재실행되지 않습니다.
```bash
docker compose -f docker-compose.dev.yml --profile infra down -v
docker compose -f docker-compose.dev.yml --profile infra --profile platform up -d --build
```

> `down -v` 옵션은 PostgreSQL 데이터가 모두 삭제됩니다. 주의해서 사용하세요.
