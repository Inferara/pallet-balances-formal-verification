# Milestone Deliverables

* Grants program submitted [PR](https://github.com/w3f/Grants-Program/pull/2606)
* Grants milestone delivery repository [PR](#TODO)

## Deliverables Table

| Number   | Deliverable   | Link   | Notes   |
|---|---|---|---|
| 0a. | License | [https://github.com/.../LICENSE](https://github.com/Inferara/pallet-balances-formal-verification/blob/main/LICENSE) | MIT |
| 0b. | Documentation | [https://github.com/Inferara/pallet-balances-formal-verification/preparation](https://github.com/Inferara/pallet-balances-formal-verification/tree/main/preparation) | This directory contains documentation for the project |
| 0c. | Reproducibility | [balances_contracts.rs](https://github.com/Inferara/pallet-balances-formal-verification/blob/main/balances_contract/lib.rs) | *ink!* implementation of `palette_balances` |
| | | [balances_contract.wat](https://github.com/Inferara/pallet-balances-formal-verification/blob/main/balances_contract/balances_contract.wat) | Annotated WASM binary compilation artifacts |
||| Check bitexact | GitHub workflow step that checks bit exactness of compiled and annotated WASM binaries |
| | | [Conformance tests](https://github.com/Inferara/pallet-balances-formal-verification/tree/main/balances_contract/conformance_tests) <br/> [![Build](https://github.com/Inferara/pallet-balances-formal-verification/actions/workflows/build_test.yml/badge.svg?branch=main)](https://github.com/Inferara/pallet-balances-formal-verification/actions/workflows/build_test.yml) | Fungible conformance tests |
| 0d. | Final Research Article | [https://github.com/.../preparing-polkadot-pallet-balances-for-formal-verification.md](https://github.com/Inferara/pallet-balances-formal-verification/blob/main/preparation/preparing-polkadot-pallet-balances-for-formal-verification.md) | A detailed research article that explains research findings and results. It includes the reproducibility guide of the `0c` deliverable, notably WASM binary compilation artifacts. Textual description of fungible traits specification along with discovered assumptions regarding execution environment, required for implementation. All public functions, involved in implementation of traits `Inspect`, `Unbalanced`, `UnbalancedHold`, `Mutate`, `InspectHold`, `MutateHold`, `UnbalancedHold`, `InspectFreeze`, `MutateFreeze` and `Balanced`. This article includes a cleaned up and annotated WASM module of `pallet_balances`. Includes Rust code that is distilled and ready to reason about. Ordinary unit tests to confirm its faithfulness to the original in a classical sense. This article describes the process we went through preparaing `pallet_balances` for future formal verification. |

>Note: The final research article will be published to [inferara.com](https://inferara.com) upon acceptance of the milestone delivery.
