# Project notes: Olist analytics

## 1. Setup and data loading

- What are the stack and versions?
  - MySQL: 8.4.11
  - Python: 3.14.8

  The tables were loaded using a python script called `load_data.py`.

- What was the final row count for each table, and did each match its CSV?

  | table                             | csv count | db count | count match? |
  | --------------------------------- | --------- | -------- | ------------ |
  | customers                         | 99441     | 99441    | ✅           |
  | orders                            | 99441     | 99441    | ✅           |
  | products                          | 32951     | 32951    | ✅           |
  | sellers                           | 3095      | 3095     | ✅           |
  | product_category_name_translation | 71        | 71       | ✅           |
  | order_items                       | 112650    | 112650   | ✅           |
  | order_payments                    | 103886    | 103886   | ✅           |
  | order_reviews                     | 99224     | 99224    | ✅           |
  | geolocation                       | 1000163   | 1000163  | ✅           |

- Which CSV columns needed fixing at load time?

  | table       | columns                                         | fix                                                              |
  | ----------- | ----------------------------------------------- | ---------------------------------------------------------------- |
  | customer    | customer_zip_code_prefix                        | we needed to enforce the str type otherwise it was taking number |
  | products    | product_name_lenght, product_description_lenght | I renamed the columns because well spelling mistake              |
  | sellers     | seller_zip_code_prefix                          | enforce str type otherwise taking as number                      |
  | geolocation | geolocation_zip_code_prefix                     | enfore as str otherwise taking as number                         |

  Also, all zip codes are exactly 5 characters

- What did you choose not to load or enforce, and why?
  - Since, geolocation is not being used and there was no unique key, i haven't given a PK to that table. I haven't referenced it to the tables as well. I've loaded the data so I can have the data but there is no PK, reference or use.
  - I have currently not referenced products table and product_category_name_translation yet. I didn't feel the need to. It is not necessary right now. If I feel the need later on, then I will.

## 2. Decisions

For each decision: what did you choose, why, and how does it change the results?

- Analysis window
  - I have used the window as '2017-02' to '2018-08'
  - The reason is that the data is very sparse in 2016 and after 2018-09.
  - The data will only be considered as noise and in fact, might interfere with analysis. Hence, I have not included that data
  - 2016 has 4, 324, and 1 orders. Jan 2017 has 800. From Feb 2017 volume is above 1,700 a month. Sep and Oct 2018 have 16 and 4
- Which order statuses count as a purchase
  - Only delivered
  - We've checked repeat customers using the data in the sanity check. canceled and unavailable orders aren’t purchases, and shipped ones may still fail, so delivered is the cleanest definition of a completed purchase.
  - 3.07% counting all statuses vs 2.97% delivered only, so the choice barely matters.
- Who counts as one person
  - customer_id should not be considered as one customer.
  - customer_unique_id is the unique customer
- How reviews and payments get reduced to one row per
  - Reviews: 551 extra rows share an order_id, so some orders have 2+ reviews. Joining directly would count those orders twice. Decision: not made yet. Candidates: average score, latest score. Plan: run the delivery analysis both ways and report whether they agree.
  - Payments: 103,886 rows for 99,440 orders (split payments). Plan: sum payment_value per order in a CTE before any join.

## 3. Data quality findings

For each issue: how many rows, what you did about it, and whether it affects any question.

- Missing dates, by status

  | order_status | missing_approved | missing_shipped | missing_delivered |
  | ------------ | ---------------- | --------------- | ----------------- |
  | canceled     | 115              | 507             | 576               |
  | delivered    | 12               | 2               | 8                 |
  | created      | 5                | 5               | 5                 |
  | unavailable  | 0                | 592             | 592               |
  | processing   | 0                | 290             | 290               |
  | invoiced     | 0                | 284             | 284               |
  | approved     | 0                | 2               | 2                 |
  | shipped      | 0                | 0               | 1081              |

  The 8 delivered orders with no delivery date are excluded from the delivery analysis

- Timestamps in the wrong order

  | invalid_approved | invalid_shipped | invalid_delivered | invalid_purchased |
  | ---------------- | --------------- | ----------------- | ----------------- |
  | 0                | 1359            | 18                | 0                 |

- Statuses with unexpected null patterns
  - delivered status is missing delivered dates: 8
  - delivered status is missing approved and shipped as well: 12 and 2.
  - This data is according to the window though
  - 1 delivered order has no payment row
- Duplicate or multi-row cases
  - There are multiple payment rows for one order. Multiple rows per order come from split payments: a voucher plus a card, or several vouchers. The evidence is: vouchers have 5,775 rows for 3,866 orders. Hence, we need to combine (order_id, payment_sequential) to form a PK
  - A similar pattern for reviews. There can be multiple reviews for one order and review is unique across a single order. Hence, the PK is a combination (review_id, order_id)

## 4. Results by question

One short block per question, in this order:

- Cohort retention
- Funnel by order status
- Revenue, AOV, categories
- RFM segments
- Delivery delay vs review score
  For each: what is the number, what scope does it cover, and what does it mean in one sentence?

## 5. Dead ends and surprises

- What did you expect that turned out different?
- What did you try that didn't work, and why?

## 6. Open questions

- What do you still need to check, or want to revisit?
