# Infra

도시락 커머스 플랫폼 로컬 개발 환경 구성 저장소입니다.
Docker Compose로 전체 인프라를 프로파일별로 기동할 수 있습니다.

---

## 폴더 구조

```
infra/
├── docker-compose.yml       # 전체 컨테이너 정의 (4개 프로파일)
├── .env.example             # 환경변수 템플릿 (복사해서 .env로 사용)
├── .gitignore
├── init-db/
│   └── 01-init.sql          # PostgreSQL DB 10개 + 계정 초기화 스크립트
├── config/
│   ├── application.yml      # 모든 서비스 공통 설정
│   ├── user-service.yml
│   ├── company-service.yml
│   ├── product-service.yml
│   ├── cart-service.yml
│   ├── order-service.yml
│   ├── payment-service.yml
│   ├── shipment-service.yml
│   ├── notification-service.yml
│   ├── review-service.yml
│   └── customer-service.yml
└── prometheus/
    └── prometheus.yml       # Prometheus 스크랩 설정
```

---

## 사전 요구사항

- Docker Desktop 설치 및 실행 중
- Docker Compose v2 이상 (`docker compose` 명령어 지원)

---

## 최초 세팅 (처음 한 번만)

### 1. 저장소 클론

```bash
git clone https://github.com/dosirak/infra.git
cd infra
```

### 2. 환경변수 파일 생성

```bash
cp .env.example .env
```

> `.env` 파일은 Git에 포함되지 않습니다. 각자 로컬에서 생성해야 합니다.
> 비밀번호를 변경하고 싶다면 `.env` 파일을 직접 수정하세요.

---

## 컨테이너 기동

### 프로파일 구성

| 프로파일 | 포함 컨테이너 | 설명 |
|---|---|---|
| `infra` | PostgreSQL, Redis, Zookeeper, Kafka, Kafdrop, Keycloak | DB/메시징 인프라 |
| `platform` | Config Server, Eureka Server, API Gateway | MSA 플랫폼 레이어 |
| `app` | 도메인 서비스 10개 | 애플리케이션 서비스 |
| `monitoring` | Prometheus, Grafana, Zipkin | 모니터링 |

### 권장 기동 순서

**1단계 — DB/메시징 인프라만 올리고 서비스는 IDE에서 실행 (개발 중 가장 많이 쓰는 패턴)**

```bash
docker compose --profile infra up -d
```

**2단계 — 플랫폼까지 올리기 (Config Server, Eureka, Gateway 필요 시)**

> 먼저 Config Server, Eureka Server, API Gateway 이미지가 빌드되어 있어야 합니다.

```bash
docker compose --profile infra --profile platform up -d
```

**3단계 — 전체 기동 (모든 서비스 Docker로 실행)**

> 모든 도메인 서비스 이미지가 빌드되어 있어야 합니다.

```bash
docker compose --profile infra --profile platform --profile app up -d
```

**모니터링 포함 전체 기동**

```bash
docker compose --profile infra --profile platform --profile app --profile monitoring up -d
```

---

## 기동 확인

### 컨테이너 상태 확인

```bash
docker compose --profile infra ps
```

모든 컨테이너의 STATUS가 `healthy` 또는 `running`인지 확인합니다.

### PostgreSQL DB 10개 생성 확인

```bash
docker exec -it postgres psql -U postgres -c "\l"
```

`user_db`, `company_db`, `order_db` 등 10개 DB가 목록에 표시되면 정상입니다.

### 각 서비스 접속 주소

| 서비스 | 주소 |
|---|---|
| PostgreSQL | `localhost:5432` (user: `postgres`, pw: `.env` 참고) |
| Redis | `localhost:6379` |
| Kafka | `localhost:9092` |
| Kafdrop (Kafka UI) | http://localhost:9000 |
| Keycloak | http://localhost:8180 |
| Config Server | http://localhost:8888 |
| Eureka Server | http://localhost:8761 |
| API Gateway | http://localhost:8080 |
| Prometheus | http://localhost:9090 |
| Grafana | http://localhost:3000 (user: `admin`, pw: `admin`) |
| Zipkin | http://localhost:9411 |

---

## 컨테이너 중지

```bash
# infra만 중지
docker compose --profile infra down

# 전체 중지
docker compose --profile infra --profile platform --profile app --profile monitoring down

# 전체 중지 + 볼륨 삭제 (DB 데이터 초기화 시)
docker compose --profile infra --profile platform --profile app --profile monitoring down -v
```

> `down -v` 옵션은 PostgreSQL 데이터가 모두 삭제됩니다. 주의해서 사용하세요.

---

## 서비스별 DB 접속 정보

각 서비스는 아래 전용 계정으로 자신의 DB에만 접근합니다.

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

> 비밀번호는 `.env.example` 참고 (기본값: `1234`)

---

## 자주 발생하는 문제

**컨테이너 이름 충돌 오류**
```
The container name "/redis" is already in use
```
→ 기존 컨테이너 제거 후 재기동:
```bash
docker rm -f postgres redis zookeeper kafka kafdrop keycloak
docker compose --profile infra up -d
```

**PostgreSQL DB가 10개 생성되지 않은 경우**

볼륨이 이미 존재하면 `init-db/01-init.sql`이 재실행되지 않습니다. 볼륨을 삭제하고 재기동하세요:
```bash
docker compose --profile infra down -v
docker compose --profile infra up -d
```
