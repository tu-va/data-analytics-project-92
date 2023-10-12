/*customers_count.csv: запрос считает общее количество покупателей из таблицы customers по customer_id*/
select
count(customer_id) as customers_count
from customers;


/*top_10_total_income.csv: отчет о 10 лучших продавцах*/
select
concat(employees.first_name, ' ', employees.last_name) as name,
count(sales.quantity) as operations,
floor(sum(sales.quantity*products.price)) as income
from sales
inner join employees on employees.employee_id = sales.sales_person_id  
inner join products on sales.product_id = products.product_id
group by concat(employees.first_name, ' ', employees.last_name)
order by income desc
limit 10;


/*lowest_average_income.csv: отчет с продавцами, чья выручка ниже средней выручки всех продавцов*/
with tab as(
select
distinct(concat(first_name, ' ', last_name)) as name,
avg(sales.quantity*products.price) as average_income
from sales
inner join employees on employees.employee_id = sales.sales_person_id  
inner join products on sales.product_id = products.product_id
group by concat(first_name, ' ', last_name)
)
select /*округление до целого+информация о продавцам, у которых сред выручка за сделку меньше средней выручки по всем продавцам*/
name,
floor(average_income) as average_income
from tab
where average_income < 
(
select /*средняя выручка по всем продавцам*/
avg(sales.quantity*products.price) 
from sales
inner join products on sales.product_id = products.product_id
)
order by average_income; /*сортировка по возрастанию средней выручки*/


/*day_of_the_week_income.csv: отчет с данными по выручке по каждому продавцу и дню недели*/
with tab as(
select
distinct(concat(first_name, ' ', last_name)) as name,
to_char(sales.sale_date, 'id') as weekdate, /*порядковый номер дня недели для сортировки*/
to_char(sales.sale_date,'day') as weekday,
floor(sum(sales.quantity*products.price)) as income
from sales
inner join employees on employee_id = sales_person_id
inner join products on sales.product_id = products.product_id
group by concat(first_name, ' ', last_name), weekdate, weekday
order by weekdate, name
)
select /*округление до целого+оставляем только имена дней недели отсортированные по США*/
name,
weekday,
income
from tab;


/*age_groups.csv с возрастными группами покупателей*/
with tab as(
select
case 
	when age between '16' and '25' then '16-25'
	when age between '26' and '40' then '26-40'
	else '40+'
end as age_category,
age
from customers
)
select  /*считаем кол-во людей по возрастным группам*/
distinct(age_category),
count(age) as count
from tab
group by age_category
order by age_category;


/*customers_by_month.csv с количеством покупателей и выручкой по месяцам*/
select 
to_char(cast(sale_date as date),'YYYY-MM') as date, /*приводим данные в вид ГОД-МЕСЯЦ*/
count(customers.customer_id) as total_customers, /*считаем кол-во покупателей по дате покупки*/
floor(sum(sales.quantity*products.price)) as income
from sales 
inner join customers on customers.customer_id = sales.customer_id /*соединяем таблицы*/
inner join products on sales.product_id = products.product_id
group by date
order by date;


/*special_offer.csv с покупателями первая покупка которых пришлась на время проведения специальных акций*/
with tab as( 
select 
row_number() over (partition by sales.customer_id order by sale_date) as row_num, /*пронумеровали покупателей по датам покупок*/
sales.customer_id,
sale_date,
price,
sales_person_id
from sales
inner join products on sales.product_id = products.product_id 
where price = 0 /*выбрали акционные покупки*/
group by sale_date, sales.customer_id, price, sales_person_id
),
tab2 as(
select 
concat(customers.first_name, ' ', customers.last_name) as customer, /*обозначили имена и фамилии покупателей*/
tab.customer_id,
sale_date,
sales_person_id
from tab
inner join customers on tab.customer_id = customers.customer_id
where row_num = 1 /*отфильтровали первые акционные покупки по покупателям*/
order by tab.customer_id
)
select 
customer,
sale_date,
concat(employees.first_name, ' ', employees.last_name) as seller /*обозначили имена и фамилии продавцов акционных товаров*/
from tab2
inner join employees on tab2.sales_person_id = employees.employee_id;