.PHONY: help setup build-platform dev dev-platform down down-all logs ps

# 기본 실행: help 출력
.DEFAULT_GOAL := help

help: ## 사용 가능한 명령어 목록
	@echo ""
	@echo "사용법: make [명령어]"
	@echo ""
	@echo "  최초 세팅"
	@echo "    setup            platform 이미지 빌드 + infra 기동 (.env 직접 생성 필요)"
	@echo ""
	@echo "  이미지 빌드"
	@echo "    build-platform   config-server, eureka-server, api-gateway 이미지 빌드"
	@echo ""
	@echo "  개발 환경 실행"
	@echo "    dev              infra만 실행 (DB, Kafka, Keycloak)"
	@echo "    dev-platform     infra + platform 실행 (Config, Eureka, Gateway 포함)"
	@echo ""
	@echo "  종료"
	@echo "    down             infra + platform 종료"
	@echo "    down-all         전체 종료 (모니터링 포함)"
	@echo ""
	@echo "  상태 확인"
	@echo "    ps               실행 중인 컨테이너 목록"
	@echo "    logs             전체 로그 스트림"
	@echo ""

# ────────────────────────────────────────────
# 최초 세팅 (처음 합류한 팀원이 1회 실행)
# ────────────────────────────────────────────
setup: ## 최초 세팅: platform 이미지 빌드 + infra 기동 (.env는 직접 생성 필요)
	@if [ ! -f .env ]; then echo "❌ .env 파일이 없습니다. .env.example을 참고해 .env를 먼저 생성하세요."; exit 1; fi

	@echo ""
	@echo "▶ [1/3] config-server 이미지 빌드 중..."
	@cd ../Config_server && chmod +x gradlew && ./gradlew build -x test -q && docker build -t dosirak/config-server:latest . -q
	@echo "    dosirak/config-server:latest 완료"

	@echo "▶ [2/3] eureka-server 이미지 빌드 중..."
	@cd ../Eureka_Server && chmod +x gradlew && ./gradlew build -x test -q && docker build -t dosirak/eureka-server:latest . -q
	@echo "    dosirak/eureka-server:latest 완료"

	@echo "▶ [3/3] api-gateway 이미지 빌드 중..."
	@cd ../Gateway_server && chmod +x gradlew && ./gradlew build -x test -q && docker build -t dosirak/api-gateway:latest . -q
	@echo "    dosirak/api-gateway:latest 완료"

	@echo "▶ [4/4] infra 기동 중..."
	@docker compose --profile infra up -d

	@echo ""
	@echo "✅ 세팅 완료! IntelliJ에서 본인 서비스를 실행하세요."
	@echo ""
	@echo "   Eureka  : http://localhost:8761  (make dev-platform 실행 후)"
	@echo "   Config  : http://localhost:8888  (make dev-platform 실행 후)"
	@echo "   Kafdrop : http://localhost:9000"
	@echo ""

# ────────────────────────────────────────────
# 이미지 빌드
# ────────────────────────────────────────────
build-platform: ## config-server, eureka-server, api-gateway 이미지 재빌드
	@echo "▶ config-server 빌드 중..."
	@cd ../Config_server && chmod +x gradlew && ./gradlew build -x test -q && docker build -t dosirak/config-server:latest .
	@echo "▶ eureka-server 빌드 중..."
	@cd ../Eureka_Server && chmod +x gradlew && ./gradlew build -x test -q && docker build -t dosirak/eureka-server:latest .
	@echo "▶ api-gateway 빌드 중..."
	@cd ../Gateway_server && chmod +x gradlew && ./gradlew build -x test -q && docker build -t dosirak/api-gateway:latest .
	@echo "✅ platform 이미지 빌드 완료"

# ────────────────────────────────────────────
# 개발 환경 실행
# ────────────────────────────────────────────
dev: ## infra만 실행 (DB/Kafka 만 필요한 경우, 서비스는 IntelliJ에서 직접 실행)
	@docker compose --profile infra up -d
	@echo ""
	@echo "✅ infra 실행 완료 — IntelliJ에서 본인 서비스를 실행하세요."
	@echo "   Kafdrop : http://localhost:9000"
	@echo ""

dev-platform: ## infra + platform 실행 (Config Server, Eureka, Gateway 포함)
	@docker compose --profile infra up -d
	@docker compose --profile infra --profile platform up -d
	@echo ""
	@echo "✅ infra + platform 실행 완료 — IntelliJ에서 본인 서비스를 실행하세요."
	@echo "   Gateway : http://localhost:8080"
	@echo "   Eureka  : http://localhost:8761"
	@echo "   Config  : http://localhost:8888"
	@echo "   Kafdrop : http://localhost:9000"
	@echo ""

# ────────────────────────────────────────────
# 종료
# ────────────────────────────────────────────
down: ## infra + platform 종료
	@docker compose --profile infra --profile platform down
	@echo "✅ 종료 완료"

down-all: ## 전체 종료 (모니터링 포함, DB 데이터 유지)
	@docker compose --profile infra --profile platform --profile app --profile monitoring down
	@echo "✅ 전체 종료 완료"

# ────────────────────────────────────────────
# 상태 확인
# ────────────────────────────────────────────
ps: ## 실행 중인 컨테이너 목록 확인
	@docker compose --profile infra --profile platform --profile app --profile monitoring ps

logs: ## 전체 로그 스트림 (Ctrl+C로 종료)
	@docker compose --profile infra --profile platform logs -f
