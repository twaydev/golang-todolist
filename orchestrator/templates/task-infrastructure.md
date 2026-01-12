# [Infrastructure] Deploy {Feature}

## Agent
**infrastructure-agent**

## Phase
Phase 4 - Deployment (Sequential)

## Objective
Update CI/CD pipeline if needed and deploy the feature to Railway with health check validation.

## Prerequisites
- Phase 3 complete (all adapters implemented)
- All tests passing (unit, BDD, integration)

## Tasks
1. **Review CI/CD** (`.github/workflows/*.yml`)
   - Check if workflow updates needed
   - Ensure new tests are included
   - Verify deployment triggers

2. **Review Docker** (`Dockerfile`)
   - Check if changes needed for new dependencies
   - Verify build still works
   - Optimize if needed

3. **Update Environment** (Railway dashboard)
   - Add any new environment variables
   - Update configurations if needed

4. **Deploy to Railway**
   ```bash
   railway up
   ```

5. **Verify Deployment**
   ```bash
   # Health check
   curl https://{app}.railway.app/health
   
   # Test new endpoint
   curl https://{app}.railway.app/api/v1/{endpoint}
   ```

6. **Run E2E Tests** (if available)
   ```bash
   make test-e2e
   ```

7. **Monitor Logs**
   ```bash
   railway logs
   ```

## Skills Used
- cicd/github-actions
- containerization/docker
- deployment/railway
- monitoring/logging

## Output
- CI/CD pipeline passing ✅
- Docker build successful ✅
- Deployment to Railway successful ✅
- Health checks passing ✅
- Feature accessible ✅

## Completion Signal
Post to Linear:
```
✅ infrastructure-agent complete

Deployment status: SUCCESS ✅
Health check: PASSING (HTTP 200) ✅
URL: https://{app}.railway.app

CI/CD pipeline: ✅ All checks passed
Docker build: ✅ Image size: {X}MB
Railway deployment: ✅ Deployed in {Y} seconds

Feature is live and accessible.

Epic complete. All acceptance criteria met.
```

## Checkpoint Validation
Run: `orchestrator/scripts/validate-phase.sh 4`
- Expected: Health check returns 200 OK
- Mark epic as Done when validated

## Final Verification Checklist
- [ ] All unit tests pass
- [ ] All BDD scenarios pass
- [ ] All integration tests pass
- [ ] Health check passes
- [ ] Feature works in production
- [ ] No errors in logs
- [ ] Performance acceptable
- [ ] Documentation updated

## References
- `.factory/droids/infrastructure-agent.yaml`
- `docs/16-cicd-pipeline.md`
- `docs/17-configuration.md`
