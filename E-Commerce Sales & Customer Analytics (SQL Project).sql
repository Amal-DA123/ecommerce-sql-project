create database ecommerce_sql_project;
use ecommerce_sql_project;

##customers table
create table customers (
	cust_id int primary key auto_increment,
    cust_name varchar(100),
    email varchar(100),
    city varchar(50),
    signup_date date
);

##Products table
create table products (
	prod_id int primary key auto_increment,
    prod_name varchar(100),
    category varchar(50),
    price decimal(10,2)
);

##orders table
create table orders (
	order_id int primary key auto_increment,
	cust_id int,
	order_date date,
	total_amount decimal(10,2),
	foreign key (cust_id) references customers(cust_id)
);

## order item table
create table order_items(
	order_item_id int primary key auto_increment,
    order_id int,
    product_id int,
    quantity int,
    item_price decimal(10,2),
    foreign key (order_id) references orders(order_id),
    foreign key (prod_id) references products(prod_id)
);
DROP TABLE IF EXISTS order_items;
CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    prod_id INT,
    quantity INT,
    item_price DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (prod_id) REFERENCES products(prod_id)
);

##payments table
create table payments (
	payment_id int primary key auto_increment,
    order_id int,
    payment_method varchar(50),
    payment_status varchar(30),
    payment_date date,
    foreign key (order_id) references orders(order_id)
    );

INSERT INTO customers (cust_name, email, city, signup_date) VALUES
('Vishnu', 'vishnu@gmail.com', 'Delhi', '2023-01-15'),
('Adeed', 'adeed@gmail.com', 'Mumbai', '2023-02-10'),
('Abhinand', 'abhinand@gmail.com', 'Bangalore', '2023-03-05'),
('Sreenandu', 'sreenandu@gmail.com', 'Chennai', '2023-03-20');

insert into products (prod_name,category,price)values
('Wireless Mouse', 'Electronics', 799),
('Bluetooth Headphones', 'Electronics', 2499),
('Office Chair', 'Furniture', 6999),
('Notebook Set', 'Stationery', 299);

insert into orders (cust_id,order_date,total_amount)values
(1, '2023-04-01', 3298),
(2, '2023-04-03', 2499),
(1, '2023-04-10', 6999),
(3, '2023-04-15', 1098);

insert into order_items (order_id,prod_id,quantity,item_price)values
(1, 1, 1, 799),
(1, 2, 1, 2499),
(2, 2, 1, 2499),
(3, 3, 1, 6999),
(4, 4, 2, 299);

insert into payments (order_id,payment_method,payment_status,payment_date)values
(1, 'Credit Card', 'Completed', '2023-04-01'),
(2, 'UPI', 'Completed', '2023-04-03'),
(3, 'Debit Card', 'Completed', '2023-04-10'),
(4, 'UPI', 'Completed', '2023-04-15');

select * from customers;
select * from products;
select * from orders;
select * from order_items;
select * from payments;

describe payments;
select order_id from orders;

INSERT INTO payments (order_id, payment_method, payment_status, payment_date)
VALUES
(1, 'Credit Card', 'Completed', '2023-04-01'),
(2, 'UPI', 'Completed', '2023-04-03'),
(3, 'Debit Card', 'Completed', '2023-04-10'),
(4, 'UPI', 'Completed', '2023-04-15');

select * from payments;

## -combining tables using joins
select 
	o.order_id,
    o.order_date,
    c.cust_name,
    p.prod_name,
    oi.quantity,
    oi.item_price
from orders o
join customers c on o.cust_id = c.cust_id
join order_items oi on o.order_id = oi.order_id
join products p on oi.prod_id = p.prod_id
order by o.order_date;

## found total revenue by product category using joins
select 
	p.category,
    sum(oi.quantity * oi.item_price) as total_revenue
from order_items oi
join products p on oi.prod_id = p.prod_id
group by p.category
order by total_revenue
desc ;


## found top revenue generated products using joins
select 
	p.prod_name,
    sum(oi.quantity * oi.item_price) as prod_revenue
from order_items oi
join products p on oi.prod_id = p.prod_id
group by p.prod_name
order by prod_revenue 
desc 
limit 5;


## Customer wise total spending
select
	c.cust_name,
    sum(o.total_amount) as total_spent
from orders o
join customers c on o.cust_id = c.cust_id
group by c.cust_name
order by total_spent
desc;


## avg order value
select
	round(avg(total_amount), 2) as average_order_value
from orders;


## MONTHLY SALES TREND
select
	date_format(order_date, '%y-%m') as month,
    sum(total_amount) as monthly_revenue
from orders
group by month
order by month;


#Payment method
select
	payment_method,
    count(*) as transaction_count
from payments
where payment_status = 'COMPLETED'
group by payment_method
order by transaction_count 
desc;


select
	cust_id,
    count(order_id) as total_orders,
    case
		when count(order_id) > 1 Then 'REPEAT CUSTOMER'
        else 'NEW CUSTOMER'
	end as customer_type
from orders
group by cust_id;


with monthly_sales as(
	select
		date_format(order_date, '%y-%m') as month,
        sum(total_amount) as revenue
	from orders
    group by month 
)
select
	month,
    revenue,
    LAG(revenue) over (order by month) as previous_month_revenue,
    ROUND(
		(revenue-LAG(revenue) OVER (order by month))/
        LAG(revenue) OVER (order by month)*100,2
	) AS growth_percentage
from monthly_sales;


select 
	c.cust_name,
    sum(o.total_amount)as total_spent,
    rank() OVER (order by sum(o.total_amount) Desc)as spending_rank
from orders o
join customers c on o.cust_id = c.cust_id
group by c.cust_name;


with product_revenue as (
	select
		p.category,
        p.prod_name,
        sum(oi.quantity * oi.item_price) as revenue
	from order_items oi
    join products p on oi.prod_id = p.prod_id
    group by p.category, p.prod_name
)
select
	category,
    prod_name,
    revenue
from (
	select
		*,
        row_number() OVER (partition by category order by revenue desc) as rn
	from product_revenue
)ranked
where rn = 1;

CREATE INDEX idx_orders_cust_id ON orders(cust_id);
CREATE INDEX idx_orders_order_date ON orders(order_date);

CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_prod_id ON order_items(prod_id);

CREATE INDEX idx_payments_order_id ON payments(order_id);

EXPLAIN
SELECT
    p.category,
    SUM(oi.quantity * oi.item_price) AS total_revenue
FROM order_items oi
JOIN products p ON oi.prod_id = p.prod_id
GROUP BY p.category;

## " I used EXPALIN to verify query performanceand confirmed that MySQL
##	 uses indexes on join columns, reducing full table scans and improving execution efficiency."