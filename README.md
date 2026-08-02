# Marketing Funnel Analysis | Python, SQL

A user-journey analysis of **90,400 users across 5 relational tables** to identify where customers leave the purchase funnel, which segments are most affected, and where conversion improvements should be prioritised.

---

## 🚀 Business Impact Snapshot

<img width="1090" height="145" alt="image" src="https://github.com/user-attachments/assets/a2694fd8-210b-450f-b143-767108addd01" />

- Only **452 of 90,400 users converted**, resulting in an overall conversion rate of **0.50%**.
- **Payment → Confirmation** recorded the highest proportional abandonment at **92.50%**.
- **Search → Payment** caused the largest absolute loss, with **39,170 users** leaving the funnel.
- Desktop represented **66.6% of users** but converted at only **0.25%**, compared with **1.00% on Mobile**.

---

## 🏢 Business Problem

The business was attracting users to the platform, but very few were completing their purchases. The main challenge was to determine:

- where the largest conversion leakage occurred,
- which customer segments were most affected,
- and which improvements could increase purchases without acquiring additional users.

---

## ❓ Business Questions

This analysis answers:

- Which funnel stage should be optimised first?
- Where is the highest absolute and proportional customer loss?
- Which user segment represents the largest untapped opportunity?
- Is weaker conversion linked to traffic volume or funnel efficiency?
- How does performance differ by device and monthly user group?

---

## 📂 Dataset

The analysis uses five relational tables:

| Table | Description |
|---|---|
| `users` | User ID, date, device and gender |
| `home` | Users who reached the home page |
| `search` | Users who reached the search page |
| `payment` | Users who reached the payment page |
| `payment_confirmation` | Users who completed their purchase |

### Analysis workflow

```text
Raw relational tables
        ↓
Data-quality validation
        ↓
User-level funnel model
        ↓
Funnel and segment analysis
        ↓
Business recommendations
```

---

## 📊 Funnel Performance

| Funnel transition | Users reached | Users progressed | Conversion rate | Abandonment rate |
|---|---:|---:|---:|---:|
| Home → Search | 90,400 | 45,200 | 50.00% | 50.00% |
| Search → Payment | 45,200 | 6,030 | 13.34% | 86.66% |
| Payment → Confirmation | 6,030 | 452 | 7.50% | 92.50% |

<img width="1087" height="546" alt="image" src="https://github.com/user-attachments/assets/3e04dec7-6513-41a0-b7ff-1b02956a84e7" />


### Key Finding

The funnel produced only **452 completed purchases**, resulting in an overall conversion rate of **0.50%**.

Two separate bottlenecks were identified:

- **Search → Payment** created the largest absolute loss of **39,170 users**.
- **Payment → Confirmation** recorded the highest proportional abandonment at **92.50%**.

The first reflects a large loss in purchase progression, while the second affects users who had already reached the payment stage.

---

## 🖥️ Device Opportunity

| Device | Users | User share | Overall conversion |
|---|---:|---:|---:|
| Desktop | 60,200 | 66.6% | 0.25% |
| Mobile | 30,200 | 33.4% | 1.00% |

Both devices recorded the same **50.00% Home → Search conversion**, indicating similar early-stage interest.

However, Desktop users were less likely to progress through the later stages. Despite accounting for approximately **2× the Mobile user base**, Desktop converted at only **one-fourth of the Mobile rate**.

This makes Desktop the largest segment-level opportunity for improving conversions from existing traffic.

<img width="1020" height="545" alt="image" src="https://github.com/user-attachments/assets/8795c53a-94b0-449e-8696-0e8061662a04" />


---

## 📅 Monthly User-Group Analysis

Users associated with the **March and April groups** showed weaker funnel performance than users associated with January and February.

This difference should be treated as an area for further investigation rather than proof of a specific time-based decline. The funnel-stage tables do not contain event timestamps, so monthly groups are based on the date recorded in the users table.

Potential areas for investigation include:

- traffic quality,
- campaign sources,
- product or pricing changes,
- website performance,
- checkout-related issues.

<img width="1086" height="537" alt="image" src="https://github.com/user-attachments/assets/0ac931b1-800c-41ce-9e0d-39186a489466" />



---

## 🔍 Key Findings

### 1. Payment completion is the weakest transition

Only **7.50%** of users who reached the Payment stage completed their purchase, resulting in **92.50% abandonment** at the final step.

### 2. Search → Payment causes the largest volume loss

The business lost **39,170 users** between Search and Payment, the largest absolute drop-off in the funnel.

### 3. Desktop is the largest untapped segment

Desktop accounted for **66.6% of users**, but its **0.25% overall conversion rate** was four times lower than Mobile.

### 4. Gender is a low-priority factor

Male and Female users showed minimal differences in conversion, making gender-based optimisation less important than stage- and device-level improvements.

---

## ✅ Business Recommendations

### 1. Investigate Payment → Confirmation first

- Analyse payment failure logs and user abandonment.
- Review OTP, gateway and bank-decline issues.
- Simplify checkout and payment steps.
- Collect feedback from users unable to complete payment.

The dataset identifies where users leave but does not confirm the underlying reason.

### 2. Improve the Desktop purchase journey

- Review the complete Desktop funnel.
- Conduct usability testing across later stages.
- Simplify checkout forms and navigation.
- Validate changes through A/B testing.

Improving Desktop performance could affect an existing base of **60,200 users** without requiring additional traffic.

### 3. Strengthen Search → Payment progression

- Improve search relevance and product recommendations.
- Strengthen product information and trust signals.
- Highlight popular products, offers and pricing.
- Test personalised recommendations.

These actions should be prioritised after investigating the more urgent Payment → Confirmation bottleneck.

---

## SQL Data Model

The five source tables were combined into a reusable user-level SQL view with **one record per user**.

The model included user attributes, funnel-stage indicators, conversion status, and drop-off classification, and was used to create summary views for funnel, device, and monthly performance.

Validation confirmed:

- **90,400 unique users** in the final model,
- **100% reconciliation** between source tables and analytical views,
- **452 confirmed purchases** across all outputs.

---

## 🛠️ Tools Used

- **Python:** Pandas, NumPy, Matplotlib and Seaborn
- **MySQL:** joins, data validation, conditional logic and analytical views
- **Jupyter Notebook:** analysis and business documentation
- **GitHub:** project organisation and version control

---

## 📁 Repository Structure

```text
Marketing-Funnel-Analysis/
│
├── README.md
│
├── data/
│   ├── user_table.csv
│   ├── home_page_table.csv
│   ├── search_page_table.csv
│   ├── payment_page_table.csv
│   └── payment_confirmation_table.csv
│
├── notebooks/
│   ├── marketing_funnel_analysis.ipynb
│   └── marketing_funnel_analysis.html
│
├── sql/
│   └── marketing_funnel_analysis.sql
│
├── images/
│   ├── kpi_cards.png
│   ├── funnel_overview.png
│   ├── stage_conversion.png
│   ├── device_analysis.png
│   └── monthly_analysis.png
│
└── requirements.txt
```

---

## ⚠️ Limitations

- Funnel-stage tables do not contain event timestamps.
- The dataset identifies where users leave, but not why they leave.
- Payment failures, behavioural data, pricing, campaign sources and customer feedback were unavailable.
- Recommendations should be validated through technical logs, behavioural analysis and A/B testing.
- The dataset did not include revenue information, so the financial impact of conversion improvements could not be quantified.

---

## 🎯 Conclusion

The main opportunity is not simply acquiring more users, but converting more of the **90,400 users already entering the funnel**.

Payment completion should be investigated first due to **92.50% abandonment**, while Desktop represents the largest segment opportunity with **66.6% of users** but only a **0.25% conversion rate**.

Prioritising these bottlenecks could improve completed purchases without proportionally increasing customer-acquisition spending.
