# Task A 
## No Index

| Query | Prediction | Actual result |
|---|---|---|
| `technician = 'Beier'` | SCAN | SCAN |
| `machine_name = 'cnc-02'` | SCAN | SCAN |
| `technician LIKE '%ei%'` | SCAN | SCAN |

## With Index

| Query | Before index | After index |
|---|---|---|
| `technician = 'Beier'` | SCAN | SEARCH |
| `machine_name = 'cnc-02'` | SCAN | SCAN |
| `technician LIKE '%ei%'` | SCAN | SCAN |

## Breaking the Index

I tested the query by by wraping the indexed column inside a Lower() function, which as predicted broke the index. Explain query showed that Sqlite performed a full table scan despite having the 'Technician' column indexed. 


# Task B

## Query:

``` 
SELECT *
FROM maint_job
WHERE technician = 'Beier';
```

## My Translation: 
```
σ technician = 'Beier'(maint_job)
```

## AI's Translation:
```
σ technician = 'Beier'(maint_job)
```

# Task C

Task performed solo and unfortunately not in class hence pod exchange activity can not be performed. 

# Task 1 

## Prompt: 
"SQLite schema: customer(customer_id, name, city), product(product_id, sku, price), orders(order_id, customer_id, ordered_on, status), order_line(order_id, product_id, qty). Write a query that returns, for each city, the number of distinct customers and the total revenue (sum of qty*price) of orders placed in 2025, ordered by revenue descending."

## AI's Answer:

```
EXPLAIN QUERY PLAN
SELECT c.city, COUNT(DISTINCT c.customer_id) AS customers,
       SUM(ol.qty * p.price) AS revenue
FROM customer c
JOIN orders o     ON o.customer_id = c.customer_id
JOIN order_line ol ON ol.order_id = o.order_id
JOIN product p    ON p.product_id = ol.product_id
WHERE o.ordered_on >= '2025-01-01' AND o.ordered_on < '2026-01-01'
GROUP BY c.city
ORDER BY revenue DESC;

``` 

## Prediction: 

From previous understanding I know that SEARCH is only applied to indexed columns and as we have not created any indexes, my prediction is that Sqlite would use SCAN for all the tables. 

## Qurey Plan: 

``` 
QUERY PLAN
|--SCAN ol
|--SEARCH o USING INTEGER PRIMARY KEY (rowid=?)
|--SEARCH c USING INTEGER PRIMARY KEY (rowid=?)
|--SEARCH p USING INTEGER PRIMARY KEY (rowid=?)
|--USE TEMP B-TREE FOR GROUP BY
|--USE TEMP B-TREE FOR count(DISTINCT)
`--USE TEMP B-TREE FOR ORDER BY

``` 

### Note:
Prediction was wrong due to misinformation. Turns out Sqlite can use SEARCH even if we don't explicitly index columns on our own. It used the primary keys as row IDs to search for specific data.

# Task 2 

## Indexes: 

I tested two potential indexes independently:

- ix_orders_ordered_on on orders(ordered_on). 
- ix_orderline_order on order_line(order_id).

## Result:

| Experiment | Median (ms) | Plan changed? |
|---|---:|---|
| Baseline | 99.43 | — |
| Index A: ordered_on | 97.87 | No |
| Index B: order_id | 98.60 | No |

### Note: 

Both indexes produced identical query plans to the baseline unindexed query. No meaningful improvement in performance.


## Query Plans:

### Baseline: 
``` 
QUERY PLAN
|--SCAN ol
|--SEARCH o USING INTEGER PRIMARY KEY (rowid=?)
|--SEARCH c USING INTEGER PRIMARY KEY (rowid=?)
|--SEARCH p USING INTEGER PRIMARY KEY (rowid=?)
|--USE TEMP B-TREE FOR GROUP BY
|--USE TEMP B-TREE FOR count(DISTINCT)
`--USE TEMP B-TREE FOR ORDER BY

``` 
### Positive Result: 
Using order_line(order_id)

```
SCAN o
SEARCH c USING INTEGER PRIMARY KEY (rowid=?)
SEARCH ol USING INDEX ix_orderline_order (order_id=?)
SEARCH p USING INTEGER PRIMARY KEY (rowid=?)
USE TEMP B-TREE FOR GROUP BY
USE TEMP B-TREE FOR count(DISTINCT)
USE TEMP B-TREE FOR ORDER BY

```

### Negative Result: 

Using orders(ordered_on)
```
SCAN ol
SEARCH o USING INTEGER PRIMARY KEY (rowid=?)
SEARCH c USING INTEGER PRIMARY KEY (rowid=?)
SEARCH p USING INTEGER PRIMARY KEY (rowid=?)
USE TEMP B-TREE FOR GROUP BY
USE TEMP B-TREE FOR count(DISTINCT)
USE TEMP B-TREE FOR ORDER BY
``` 
### Conclusion:

An index does not automatically improve query performance. Its usefulness depends on the query structure, data distribution, selectivity, and join order. The experiments also demonstrate that an index can improve a particular execution plan without necessarily making that plan faster than SQLite's original choice.

# Task 3 

## Script Output: 

``` 
normal   : [(1, 'Customer 1')]
injected : [(1, 'Customer 1'), (2, 'Customer 2'), (3, 'Customer 3')] ...
safe     : []
``` 

## Payload: 
```
' OR '1'='1 
```
### Escaping vs Bound-Parameters: 

SQL syntax can behave differently depending on the context, such as identifiers, numeric values, encodings and different SQL operations. A manually written filter might miss an unexpected input or fail when the query structure changes. Bound parameters solve this problem by separating SQL instructions from user-provided data. The database driver handles the correct representation of the input, ensuring that user input is treated as a value rather than executable SQL.

# Task 4 

## Query: 

``` 
SELECT c.city, COUNT(DISTINCT c.customer_id) AS customers,
       SUM(ol.qty * p.price) AS revenue
FROM customer c
JOIN orders o     ON o.customer_id = c.customer_id
JOIN order_line ol ON ol.order_id = o.order_id
JOIN product p    ON p.product_id = ol.product_id
WHERE o.ordered_on >= '2025-01-01' AND o.ordered_on < '2026-01-01'
GROUP BY c.city
ORDER BY revenue DESC;
``` 

## Algebra: 
```
τ_revenue DESC (
    γ_city;
      COUNT(DISTINCT customer_id) → customers,
      SUM(qty × price) → revenue
    (
        customer
        ⋈_{customer.customer_id = orders.customer_id}
        σ_{ordered_on >= '2025-01-01' AND ordered_on < '2026-01-01'}(orders)
        ⋈_{orders.order_id = order_line.order_id}
        order_line
        ⋈_{order_line.product_id = product.product_id}
        product
    )
)

```