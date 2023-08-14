-- 1. What is the total amount each customer spent at the restaurant?

select customer_id, sum(price) as Total_amount from sales s 
join menu m on s.product_id = m.product_id
group by customer_id;

-- 2. How many days has each customer visited the restaurant?

select customer_id, count(order_date) as No_of_days from sales 
group by customer_id;

-- 3. What was the first item from the menu purchased by each customer?

select customer_id, order_date, group_concat( product_name)  from sales s 
join menu m on s.product_id = m.product_id
where order_date in (select min(order_date) from sales)
group by customer_id, order_date;

-- 4.What is the most purchased item on the menu and how many times was it purchased by all customers?

select product_name, count(order_date)  as product_count from menu m
join sales s on m.product_id = s.product_id
group by 1
order by count(order_date) desc
limit 1

-- 5.Which item was the most popular for each customer?

select customer_id, group_concat(product_name) as fav_items from (select customer_id, product_name, 
rank() over(partition by customer_id order by count(m.product_id) desc) as rn from sales s
join menu m on m.product_id = s.product_id
group by 1,2) subquery 
where rn = 1
group by 1

-- 6. Which item was purchased first by the customer after they became a member?

select customer_id, product_name, order_date from (
select mr.customer_id, order_date, product_id,
rank() over(partition by mr.customer_id order by order_date) rn 
from sales s
join members mr on mr.customer_id = s.customer_id 
where order_date >= join_date) s 
join menu m on m.product_id = s.product_id 
where rn = 1 
order by 1

----------------- Or using cte --------------------------

with cte as (select mr.customer_id, order_date, product_id,
rank() over(partition by mr.customer_id order by order_date) rn 
from sales s
join members mr on mr.customer_id = s.customer_id 
where order_date >= join_date)
select customer_id, product_name, order_date 
from cte c
join menu m on m.product_id = c.product_id 
where rn = 1 
order by 1

-- 7. Which item was purchased just before the customer became a member?

select customer_id, order_date, group_concat(product_name) as products from (
select mr.customer_id, order_date, product_id,
rank() over(partition by mr.customer_id order by order_date desc) rn 
from sales s
join members mr on mr.customer_id = s.customer_id 
where order_date < join_date) s 
join menu m on m.product_id = s.product_id 
where rn = 1 
group by 1,2
order by 1

-- 8. What is the total items and amount spent for each member before they became a member?

select customer_id, count(distinct product_name) as Total_items, sum(m.price) total_price from (
select mr.customer_id, order_date, product_id
from sales s
join members mr on mr.customer_id = s.customer_id 
where order_date < join_date) s 
join menu m on m.product_id = s.product_id 
group by 1
order by 1

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select customer_id, sum(case when product_name = 'sushi' then price*20 else price*10 end) as total_points
from sales s 
join menu m on s.product_id = m.product_id
group by 1 

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
	   not just sushi - how many points do customer A and B have at the end of January?
       
select s.customer_id, sum(case when order_date >= join_date and order_date = join_date + interval 6 day then price*20
when product_name = 'sushi' then price*20 else price*10 end) total_points from sales s 
join menu m on s.product_id = m.product_id
join members mr on mr.customer_id = s.customer_id
where order_date < '2021-01-31'
group by 1
     
-- Bonus Question : Join all the things 

select s.customer_id, order_date, product_name, price, 
case when order_date >= join_date then 'Y' else 'N' end dannys_member
from sales s left join menu m on s.product_id = m.product_id
left join members me on s.customer_id = me.customer_id;

-- Bonus Question : Rank all the things 

select *, case when dannys_member = 'N' then 'null'
else dense_rank() over(partition by customer_id, dannys_member order by order_date) end ranking
from (select s.customer_id, order_date, product_name, price, 
case when order_date >= join_date then 'Y' else 'N' end dannys_member
from sales s left join menu m on s.product_id = m.product_id
left join members me on s.customer_id = me.customer_id) Subquery; 
