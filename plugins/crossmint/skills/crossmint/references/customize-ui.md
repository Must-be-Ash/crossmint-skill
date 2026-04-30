# Customize UI

> Style the card verification and spending authorization modals to match your brand.

## Overview

The card enrollment and spending authorization flows render a verification modal (passkey prompt) to the user. You can customize the look and feel of this modal using the `appearance` prop, which both verification components accept.

* **`PaymentMethodAgenticEnrollmentVerification`**: One-time card enrollment step. Shown when an enrollment's status is `"pending"` and needs passkey verification.
* **`OrderIntentVerification`**: Spending authorization step. Shown when an order intent's phase is `"requires-verification"`.

## How to customize the appearance

The appearance object has two top-level keys: **`variables`** (global design tokens) and **`rules`** (per-element overrides).

<Tabs>
  <Tab title="Variables">
    Global design tokens that apply across the entire modal.

    | Token                        | What it controls                                                                                        |
    | ---------------------------- | ------------------------------------------------------------------------------------------------------- |
    | `fontFamily`                 | Font stack for all text                                                                                 |
    | `fontSizeUnit`               | Base body font size (e.g. `"14px"`). Title, small, error, input, and passkey sizes scale proportionally |
    | `spacingUnit`                | Base section spacing (e.g. `"16px"`). Modal, input, button-gap, and option-gap scale proportionally     |
    | `borderRadius`               | Default border radius for modal, input, button, and option elements                                     |
    | `colors.accent`              | Primary/brand color — buttons, focus rings, radio selected state, spinner                               |
    | `colors.textPrimary`         | Main text color and button text                                                                         |
    | `colors.textSecondary`       | Secondary and placeholder text                                                                          |
    | `colors.backgroundPrimary`   | Surface/card background                                                                                 |
    | `colors.backgroundSecondary` | Input background, secondary button background                                                           |
    | `colors.border`              | Default border for modal, inputs, and radio                                                             |
    | `colors.danger`              | Error text, error border, error icon                                                                    |
    | `colors.success`             | Success icon, success background                                                                        |

    <Info>
      The SDK auto-infers missing color tokens from the ones you provide. For example, setting only `backgroundPrimary` will derive `textPrimary`, `textSecondary`, `backgroundSecondary`, and `border` automatically.
    </Info>
  </Tab>

  <Tab title="Rules">
    Per-element overrides that take precedence over variables.

    | Rule              | Customizable properties                                                                                     |
    | ----------------- | ----------------------------------------------------------------------------------------------------------- |
    | `Overlay`         | `colors.background` (backdrop behind the modal)                                                             |
    | `Modal`           | `borderRadius`, `colors.border`                                                                             |
    | `Input`           | `borderRadius`, `colors.background`, `colors.border`                                                        |
    | `PrimaryButton`   | `borderRadius`, `colors.text`, `colors.background`, `hover.colors.background`, `disabled.colors.background` |
    | `SecondaryButton` | `colors.text`, `colors.background`, `hover.colors.background`                                               |
    | `CloseButton`     | `colors.background`, `hover.colors.background`                                                              |
    | `Radio`           | `colors.border`, `selected.colors.border`, `selected.colors.background`, `selected.colors.dot`              |
  </Tab>
</Tabs>

## Example

You do not need to specify everything. The SDK infers missing colors:

```tsx theme={null}
import { OrderIntentVerification } from "@crossmint/client-sdk-react-ui";

<OrderIntentVerification
    orderIntent={orderIntent}
    appearance={{
        variables: {
            colors: {
                accent: "#6366f1",
                backgroundPrimary: "#1e1e2e",
            },
        },
    }}
    onVerificationComplete={() => {}}
    onVerificationError={(err) => console.error(err)}
/>
```

This alone will auto-derive `textPrimary`, `textSecondary`, `backgroundSecondary`, and `border` from the dark background, and use the accent color for buttons, focus rings, and radio selections.
