--#QUESTION 1 What is the total amount each customer spent at the restaurant?

SELECT members.customer_id AS ID, SUM (menu.price) as AMT 
FROM dannys_diner.members 
	RIGHT JOIN dannys_diner.sales
    ON sales.customer_id=members.customer_id
    RIGHT JOIN dannys_diner.menu
    ON sales.product_id=menu.product_id
GROUP BY ID
HAVING members.customer_id IS NOT NULL

--#QUESTION 1 showing all customers
SELECT sales.customer_id AS ID, SUM (menu.price) as AMT 
FROM dannys_diner.members 
	FULL JOIN dannys_diner.sales
    ON sales.customer_id=members.customer_id
    FULL JOIN dannys_diner.menu
    ON sales.product_id=menu.product_id
GROUP BY ID

--QUESTION 2 How many days has each customer visited the restaurant?
SELECT sales.customer_id, COUNT (DISTINCT sales.order_date) AS days_visited
FROM dannys_diner.sales
GROUP BY sales.customer_id
ORDER BY sales.customer_id

-- QUESTION 3 What was the first item from the menu purchased by each customer?
SELECT customer_id, product_name
FROM 
	(SELECT sales.customer_id, menu.product_name, ROW_NUMBER() 
     									OVER (
                                          PARTITION by sales.customer_id
                                          order by order_date) as chronological_buy
     from dannys_diner.members
     RIGHT JOIN dannys_diner.sales
     on dannys_diner.members.customer_id=dannys_diner.sales.customer_id
     JOIN dannys_diner.menu
     on dannys_diner.sales.product_id=dannys_diner.menu.product_id
     ORDER by chronological_buy) as order_of_buy
WHERE chronological_buy=1   

--QUESTION 4 What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
    product_name, COUNT (sales.product_id) AS total_sales
FROM dannys_diner.sales 
JOIN dannys_diner.menu 
ON sales.product_id=menu.product_id
GROUP BY product_name
ORDER BY total_sales DESC
LIMIT 1;

--QUESTION 5 Which item was the most popular for each customer?
WITH ranked_buys as
	(SELECT customer_id, product_name, 
		ROW_NUMBER () over (PARTITION by customer_id
					    order by buy_freq desc) ranked_buy_freq
	FROM 
	   (SELECT dannys_diner.sales.customer_id, menu.product_name, 
			COUNT (sales.product_id) 
				over (PARTITION by sales.product_id) as buy_freq
		from dannys_diner.sales
		JOIN dannys_diner.menu
		on dannys_diner.sales.product_id=dannys_diner.menu.product_id
		Group by dannys_diner.sales.customer_id, dannys_diner.sales.product_id, menu.product_name
		ORDER BY dannys_diner.sales.customer_id, buy_freq desc) counted_buys)
SELECT customer_id, product_name
FROM ranked_buys
WHERE ranked_buy_freq=1


--QUESTION 6 Which item was purchased first by the customer after they became a member?
WITH sq AS
	(SELECT members.customer_id, members.join_date, menu.product_name, sales.order_date, 
			ROW_NUMBER () 
			OVER (PARTITION BY members.customer_id
				 ORDER BY sales.order_date)
	FROM dannys_diner.sales
	JOIN dannys_diner.menu
	ON dannys_diner.sales.product_id=dannys_diner.menu.product_id
	JOIN dannys_diner.members
	ON dannys_diner.members.customer_id=dannys_diner.sales.customer_id
	WHERE members.join_date<=sales.order_date)
SELECT customer_id, join_date, product_name, order_date
FROM sq
WHERE row_number=1

--QUESTION 7 Which item was purchased just before the customer became a member?
WITH sq AS
	(SELECT members.customer_id, members.join_date, menu.product_name, sales.order_date, 
			RANK () 
			OVER (PARTITION BY members.customer_id
				 ORDER BY sales.order_date DESC)
	FROM dannys_diner.sales
	JOIN dannys_diner.menu
	ON dannys_diner.sales.product_id=dannys_diner.menu.product_id
	JOIN dannys_diner.members
	ON dannys_diner.members.customer_id=dannys_diner.sales.customer_id
	WHERE members.join_date>sales.order_date)
SELECT customer_id, join_date, product_name, order_date
FROM sq
WHERE rank=1

--QUESTION 8 What is the total items and amount spent for each member before they became a member?
SELECT DISTINCT (members.customer_id), members.join_date, 
	COUNT (*) OVER (PARTITION BY members.customer_id) items_bought_bfr_join,
	SUM (menu.price) OVER (PARTITION BY members.customer_id) amt_spent_bfr_join
			
	FROM dannys_diner.sales
	JOIN dannys_diner.menu
	ON dannys_diner.sales.product_id=dannys_diner.menu.product_id
	JOIN dannys_diner.members
	ON dannys_diner.members.customer_id=dannys_diner.sales.customer_id
	WHERE members.join_date>sales.order_date
	ORDER BY members.customer_id

--QUESTION 9 If each $1 spent equates to 10 points and sushi has a 2x points multiplier, how many points would each customer have?
WITH order_points AS
	(SELECT members.customer_id,
		   CASE
			   WHEN menu.product_name = 'sushi' THEN "price"*20
			   ELSE "price"*10
		   END AS points
	FROM dannys_diner.members
	JOIN dannys_diner.sales
	ON dannys_diner.members.customer_id=dannys_diner.sales.customer_id
	JOIN dannys_diner.menu
	ON dannys_diner.sales.product_id=dannys_diner.menu.product_id)
SELECT customer_id, SUM (points) as points
FROM order_points
GROUP BY customer_id

-- QUESTION 10 In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi how many points do customers A and B have at the end of January?
WITH order_points AS
	(SELECT members.customer_id, sales.order_date, members.join_date,
		   CASE
			WHEN sales.order_date BETWEEN members.join_date AND members.join_date+7
			THEN "price"*20
	 		WHEN sales.order_date NOT BETWEEN members.join_date AND members.join_date+7 
	 			AND menu.product_name = 'sushi' 
			THEN "price"*20
	 		ELSE "price"*10
		   END AS points
	FROM dannys_diner.members
	JOIN dannys_diner.sales
	ON dannys_diner.members.customer_id=dannys_diner.sales.customer_id
	JOIN dannys_diner.menu
	ON dannys_diner.sales.product_id=dannys_diner.menu.product_id)
SELECT customer_id, SUM (points) as points
FROM order_points
WHERE order_date BETWEEN '2021-01-01' AND '2021-01-31'
GROUP BY customer_id