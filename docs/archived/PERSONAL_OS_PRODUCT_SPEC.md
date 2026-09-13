# Personal OS — Archived Product Specification

**Status:** Archived after completion of Windows 0.4.0  
**Current source:** 0.4.0  
**Authoritative full specification:** [archived snapshot](PERSONAL_OS_PRODUCT_SPEC_1.0.md)  
**Requirement status and execution order:** [product checklist](../PRODUCT_CHECKLIST.md)

This compact file was the active contract for implementation through Windows 0.4.0. The original 53-section specification is preserved byte-for-byte in `PERSONAL_OS_PRODUCT_SPEC_1.0.md`; completed prose and examples were removed here to reduce working context.

## Product outcome

Personal OS is a local-first personal strategy and execution system. It must connect:

```text
Vision → Horizon → Strategy → Mission → Outcome → Initiative
→ Project → Task/Session → Evidence → Review → approved Strategy update
```

The finished product must let a user answer from their own evidence:

- Where am I going, and what matters now?
- What should I do today, and why?
- What did I produce and which capability improved?
- What changed in the market or in my assumptions?
- Does the roadmap still make sense, and what should change next?

## Non-negotiable behavior

1. Progress is evidence-based; study time alone never raises readiness.
2. Meaningful work exposes a Why Path to the active mission and vision.
3. Strategy-changing recommendations show reason, evidence, risk, confidence and affected assumptions/goals.
4. Accept/Modify/Reject remains under user control. Accepted changes preserve prior strategy versions and may update future plans only through an explicit, reviewable propagation step.
5. Knowledge remains browsable and editable. Retrieval exposes source, context and why the result is relevant.
6. Sensitive data is local by default. Export/delete are explicit; no silent upload.
7. Parser or migration failures do not lose active data.
8. The six primary destinations remain Today, Mission, Strategy, Projects, Knowledge and Review. Specialized features live within them.

## Delivery definition

The project is complete only when every required row in `../PRODUCT_CHECKLIST.md` is `DONE`, automated gates pass, the golden E2E flow passes, Windows release artifacts are produced, and the remaining platform limitations are recorded accurately. Items identified as explicit non-goals in the archived specification stay excluded unless a later phase explicitly requires them.

## Scope still open

The remaining release constraints are tracked in the checklist. They are limited to platform validation that cannot run on this Windows host and security capabilities that become applicable only if a future release accepts external-provider credentials or sends data off device.

When a checklist item is implemented, update its status and evidence in the same change. Do not delete it; the checklist is the audit trail.
