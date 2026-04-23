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

## 빠른 시작 (make 명령어)

> **사전 요구사항:** `make` 명령어 사용을 위해 Xcode Command Line Tools가 설치되어 있어야 합니다.
> ```bash
> xcode-select --install
> ```

### 처음 코드 실행할때

```bash
make setup
```

> ⚠️ **실행 전에 `.env` 파일을 먼저 직접 생성해야 합니다.**
> `.env.example`을 참고해 비밀번호 등 실제 값을 채운 후 저장하세요.
> `.env` 파일이 없으면 `make setup`이 실행을 중단합니다.
> ```bash
> cp .env.example .env
> # .env 파일 열어서 비밀번호 직접 수정
> ```

**내부적으로 일어나는 일:**
1. `.env` 파일 존재 여부 확인 (없으면 중단)
2. `../Config_server`에서 Gradle 빌드 후 `dosirak/config-server:latest` Docker 이미지 생성
3. `../Eureka_Server`에서 Gradle 빌드 후 `dosirak/eureka-server:latest` Docker 이미지 생성
4. `infra` 프로파일 컨테이너 기동: **PostgreSQL, Redis, Zookeeper, Kafka, Kafdrop, Keycloak**

---

### 매일 개발 시작할 때

**DB/Kafka만 필요한 경우** (본인 서비스를 IntelliJ에서 직접 실행할 때)

```bash
make dev
```

**내부적으로 일어나는 일:**
- `infra` 프로파일 컨테이너 기동: **PostgreSQL, Redis, Zookeeper, Kafka, Kafdrop, Keycloak**
- Config Server, Eureka는 실행되지 않음 → IntelliJ에서 직접 실행하거나 `make dev-platform` 사용

---

**Config Server + Eureka까지 Docker로 띄울 때** (플랫폼 서비스가 필요한 경우)

```bash
make dev-platform
```

**내부적으로 일어나는 일:**
1. `infra` 프로파일 컨테이너 기동: **PostgreSQL, Redis, Zookeeper, Kafka, Kafdrop, Keycloak**
2. `config-server` 컨테이너 기동: **Config Server** (포트 8888, Keycloak/PostgreSQL healthy 확인 후 시작)
3. `eureka-server` 컨테이너 기동: **Eureka Server** (포트 8761, Config Server healthy 확인 후 시작)
- 기동 순서가 보장됨 (의존성 헬스체크 기반)
- API Gateway는 Milestone 4 완료 후 추가 예정

---

### platform 서비스 코드 변경 후 이미지 재빌드

```bash
make build-platform
```

**내부적으로 일어나는 일:**
- `../Config_server`, `../Eureka_Server` 각각 Gradle 빌드 후 Docker 이미지 재생성
- 컨테이너는 재시작되지 않음 → 재빌드 후 `make dev-platform` 다시 실행 필요

---

### 개발 종료

```bash
make down
```

**내부적으로 일어나는 일:**
- `infra` + `platform` 프로파일 컨테이너 전체 종료 및 삭제
- PostgreSQL 데이터는 볼륨에 유지됨 (다음 실행 시 데이터 그대로)

---

### 전체 상태 확인

```bash
make ps     # 실행 중인 컨테이너 목록 + healthy 상태 확인
make logs   # 실시간 로그 스트림 (Ctrl+C로 종료)
```

---

### 명령어 요약

| 명령어 | 기동되는 컨테이너 | 사용 시점 |
|--------|----------------|---------|
| `make setup` | PostgreSQL, Redis, Kafka, Zookeeper, Kafdrop, Keycloak | 최초 1회 |
| `make dev` | PostgreSQL, Redis, Kafka, Zookeeper, Kafdrop, Keycloak | 매일 시작 (IntelliJ로 서비스 직접 실행) |
| `make dev-platform` | 위 + Config Server, Eureka Server | 플랫폼 포함 전체 Docker로 실행 |
| `make build-platform` | (컨테이너 없음, 이미지만 빌드) | config/eureka 코드 변경 후 |
| `make down` | 전체 종료 | 개발 종료 시 |
| `make ps` | 상태 확인 | 언제든지 |

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
make ps
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
