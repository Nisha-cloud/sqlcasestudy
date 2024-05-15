CREATE TABLE res_sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO res_sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  -- Questions
  -- 1. What is the total amount each customer spent at the restaurant?
  select customer_id, sum(m.price) as totalAmount
  from res_sales r
  inner join menu m on
  r.product_id = m.product_id
  group by customer_id;
  
  -- 2. How many days has each customer visited the restaurant?
  select customer_id, count( distinct order_date) as visits
  from res_sales
  group by customer_id;
  
  -- 3. What was the first item from the menu purchased by each customer?
  WITH ordered_sales AS (
  SELECT 
    s.customer_id, 
    s.order_date, 
    m.product_name,
    DENSE_RANK() OVER (
      PARTITION BY s.customer_id 
      ORDER BY s.order_date) AS rk
  FROM res_sales s
  INNER JOIN menu m
    ON s.product_id = m.product_id
)
SELECT 
  customer_id, 
  product_name
FROM ordered_sales
WHERE rk = 1
GROUP BY customer_id, product_name;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m.product_name, COUNT(s.product_id) AS most_purchased_item
FROM res_sales s 
INNER JOIN menu m
ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY most_purchased_item DESC;

-- 5. Which item was the most popular for each customer?
with cte as (select s.customer_id as id, count(s.product_id) as cnt, dense_rank() over (partition by s.customer_id order by count(s.product_id) desc) as rnk, m.product_name as productName
from res_sales s
inner join menu m on
s.product_id = m.product_id
group by s.customer_id, m.product_name)
select id, productName, cnt
from cte
where rnk=1;

-- 6.Which item was purchased first by the customer after they became a member?
with cte as (select s.customer_id,s.product_id,m.product_name, s.order_date, mem.join_date, dense_rank() over(partition by s.customer_id order by order_date asc) as rnk
from res_sales s
left join menu m on
s.product_id = m.product_id
right join members mem on
s.customer_id = mem.customer_id
where s.order_date > mem.join_date)
select customer_id, product_name
from cte
where rnk=1;

-- 7.Which item was purchased just before the customer became a member?
with cte as (select s.customer_id,s.product_id,m.product_name, s.order_date, mem.join_date, row_number() over(partition by s.customer_id order by order_date desc) as rno
from res_sales s
left join menu m on
s.product_id = m.product_id
right join members mem on
s.customer_id = mem.customer_id
where s.order_date < mem.join_date)
select customer_id, product_name
from cte
where rno=1;

-- 8.What is the total items and amount spent for each member before they became a member?
with cte as (select s.customer_id, m.product_name, s.product_id, m.price
from res_sales s
left join menu m on
s.product_id = m.product_id
right join members mem on
s.customer_id = mem.customer_id
where s.order_date < mem.join_date)
select customer_id, count(product_id) as totalCount, sum(price) as totalAmount
from cte
group by customer_id;

-- 9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select s.customer_id, sum(CASE WHEN m.product_name='sushi' THEN 20*m.price ELSE 10*m.price END) as points
from res_sales s
inner join menu m on
s.product_id = m.product_id
group by s.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH points_calc AS (
   SELECT s.customer_id,
     (
       CASE
         WHEN DATEDIFF(m.join_date, s.order_date) >= 0 AND DATEDIFF(m.join_date, s.order_date) <= 6 THEN price * 10 * 2
         WHEN product_name ='sushi' THEN price * 10 * 2
         ELSE price * 10
       END
     ) as points
   FROM res_sales s
   INNER JOIN menu mu
   ON s.product_id = mu.product_id
   INNER JOIN members m
   ON s.customer_id = m.customer_id
   WHERE MONTH(s.order_date) = 1 AND YEAR(s.order_date) = 2021
 )
 SELECT customer_id, SUM(points) AS points_total
 FROM points_calc
 GROUP BY customer_id;






