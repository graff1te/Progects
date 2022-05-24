--- ������� 1. 
-- � ����� ������� ������ ������ ���������?

--- �������: (2 ������)
-- 1. ������� ������, � ������� ������� ���������� ������� � �������-����������� airports.
-- 2. �� ���������� ������� �������� ������ ��, ���������� ������� > 1

select city, airports
from (
	select city, count (airport_code) as airports
	from airports
	group by city 
) a
where airports > 1

--------------------------------------------------------------------------------------------
--- ������� 2. 
-- � ����� ���������� ���� �����, ����������� ��������� � ������������ ���������� ��������?
-- � ������� ����������� ������ ���� ������������: ���������

--- �������: (7 ����������)
-- 1. � ���������� max_range_plane ������� ���������, ��������� �� �������� � ��������� ����� �������.
-- 2. ����� � ���������� - ��� � ����� �������� � ����� ������.
--    ����, �� ��������, ��� ����� ���� ��� ������ ����� �������� ��� ������ ����� ������.
--    �������, ������������ ������� ����� JOIN (inner) ����� ���������� ������ �� ������� flights, 
--    � �����, �������� �� ���, ����� LEFT JOIN �������� �� ��� �� �������.
-- 3. ��������� ������ 2 ��������� � ����������� max_range_plane ����� INNER JOIN.
--    � ���������� �������� ������ ��������� � ���������� ������������ ���������.
--    ���������� ��� �� �������� ���������.

select airport_name, model as aicraft_model, range as aicraft_range
from airports a
join flights f on f.departure_airport = a.airport_code
left join flights f2 on f2.arrival_airport = a.airport_code
join (
	select model, aircraft_code, range
	from aircrafts
	order by range desc limit 1
) as max_range_plane on max_range_plane.aircraft_code = f.aircraft_code 
group by airport_name, model, range

--------------------------------------------------------------------------------------------
--- ������� 3.
-- ������� 10 ������ � ������������ �������� �������� ������
-- � ������� ����������� ������ ���� ������������: �������� LIMIT

--- �������:
-- 1. �������� �� ������������ ������� ������ �����������.
-- 2. ��������� �������, ����� ������ ������������� ��������.
-- 3. ��������� ��������� �� �������� � ��������� ������ 10.

select flight_id, actual_departure - scheduled_departure as delay
from flights f 
where actual_departure notnull 
order by delay desc limit 10

--------------------------------------------------------------------------------------------
--- ������� 4. 
-- ���� �� �����, �� ������� �� ���� �������� ���������� ������?
-- � ������� ����������� ������ ���� ������������: ������ ��� JOIN

--- �������: (127899 ������)
-- 1. �� ���� ������� ������������ ������������ ����� ������, 
--    ����� ��� ���� ��� ������������� ������ ����������� ������.
-- 2. �������� ��� ������ ������������ ������������ ���������� ������.
-- 3. ��������� ������������ �� ������������� ��������� ������� ���������� �������.
-- 4. ������� ���������� �������.

select count(*) as bookings_without_boarding_no
from bookings b 
left join tickets t on t.book_ref = b.book_ref 
left join boarding_passes bp on bp.ticket_no = t.ticket_no 
where boarding_no is null

--------------------------------------------------------------------------------------------
--- ������� 5.1. 
-- ������� ��������� ����� ��� ������� �����, �� % ��������� � ������ ���������� ���� � ��������.
-- � ������� ����������� ������ ���� ������������: ���������� ��� cte

--- �������:
-- 1. ������� CTE, � ������� ������� ��������������� ������� �� �� ����������� "seats": 
--    ������� ����� � ���������� �� ���������.
-- 2. ����� ������� � ����������� �������� "boarding_passes" � ��������� ���������� � ������ "flights".
-- 3. ��������� �� ����� CTE � ���������������� ������� ��.
-- 4. ������� ��������� ����� �� �����: 
--    ������� ����� ���������������� � ����������� ���������� ������� � ����������� �� ������� �����.
-- 5. ������� % ��������� ����:
--    ��������� ����� �������� � ���� NUM ��� ����������� ������� �� �������, ����� �� ��������������� � *100. ���������.

with cte as (
	select s.aircraft_code, count (s.seat_no) as plane_capacity
	from seats s 
	group by s.aircraft_code )
select f.flight_id, cte.plane_capacity, cte.plane_capacity - count(boarding_no) as seats_vocant, 
	round((cte.plane_capacity - count(boarding_no))::numeric / cte.plane_capacity *100) as "%_vocant"
from boarding_passes bp 
join flights f on f.flight_id = bp.flight_id 
join cte on cte.aircraft_code = f.aircraft_code 
group by f.flight_id, cte.plane_capacity

--- ������� 5.2. 
-- �������� ������� � ������������� ������ - ��������� ���������� ���������� ���������� ���������� 
-- �� ������� ��������� �� ������ ����. �.�. � ���� ������� ������ ���������� ������������� ����� - 
-- ������� ������� ��� �������� �� ������� ��������� �� ���� ��� ����� ������ ������ �� ����.
-- � ������� ����������� ������ ���� ������������: ������� �������

--- �������:
-- 1. ������ ������� � ����������� SUM, � ������� ���������� ����������� ���������� ������� � ����������� �� ������� �����. 
-- 2. ��������� ���� � ���� ���������� � ����������� ��� ������, ����� timestamp. 

with cte as (
	select s.aircraft_code, count (s.seat_no) as plane_capacity
	from seats s 
	group by s.aircraft_code )
select departure_airport, actual_departure::date, f.flight_id, cte.plane_capacity, 
	cte.plane_capacity - count(boarding_no) as seats_vocant, 
	round((cte.plane_capacity - count(boarding_no))::numeric / cte.plane_capacity *100) as "%_vocant", 
	count(boarding_no) as seats_occupied,
	sum (count(boarding_no)) over (partition by departure_airport, actual_departure::date order by departure_airport, actual_departure) as seats_occupied_accumulation
from boarding_passes bp 
join flights f on f.flight_id = bp.flight_id 
join cte on cte.aircraft_code = f.aircraft_code 
group by f.flight_id, cte.plane_capacity

-- * � ������ ������������� ������ � ���������� �� ����� ����� � ������������� �������� actual_departure, ������� ��������� ����������� �� ����������:
--   sum (count(boarding_no)) over (partition by departure_airport, coalesce(actual_departure::date, scheduled_departure::date) order by departure_airport, coalesce(actual_departure, scheduled_departure)) as seats_occupied_accumulation

-------------------------------------------------------------------------------------------------
--- ������� 6. 
-- ������� ���������� ����������� ��������� �� ����� ��������� �� ������ ����������.
-- � ������� ����������� ������ ���� ������������: ��������� | �������� ROUND

--- �������:
-- 1. � ������� "flights" ���������� ���������� ������ � ������������ �� ������� �� 
--    � �������� � ���� NUM ��� ����������� ������� �� �������.
-- 2. ����� ���������� ��������� �� ���������, � ������� ������� ����� ���-�� ���� ������ � *100
-- 3. ��������� � �������� ��������� 1.

select aircraft_code, count(flight_id) as flights, 
	round(count(flight_id)::numeric / (
		select count(flight_id) 
		from flights) *100, 1) as "%_flights"
from flights a 
group by aircraft_code

----------------------------------------------------------------------------------------------------
--- ������� 7. 
-- ���� �� ������, � ������� ����� ��������� ������-������� �������, ��� ������-������� � ������ ��������?
-- � ������� ����������� ������ ���� ������������: CTE

--- �������: (���)
-- 1. ������� CTE, � ������� ������� ����������� ��������� �������� ������-������� � ���������� �� ������.
-- 2. ������� CTE2, � ������� ������� ������������ ��������� �������� ������-������� � ���������� �� ������.
-- 3. ����� ���������� "airports" � ��������.
-- 4. ��������� ��������� ���������� (arrival_airport) � ������� "flights" ���������� �������.
-- 5. ��������� ���������� ���������� �������� ������������ � �� ���������� �� ����� CTE.
-- 6. ��������� �������: ����������� ��������� �������� ������-������� ������� ���� ������ ��������� �������� ������-�������.

with cte as (
	select flight_id, fare_conditions, min (amount) as min_business_amount
	from ticket_flights tf 
	where fare_conditions = 'Business'
	group by flight_id, fare_conditions ),
	cte2 as (
	select flight_id, fare_conditions, max(amount) as max_economy_amount
	from ticket_flights tf 
	where fare_conditions = 'Economy' 
	group by flight_id, fare_conditions )
select f.flight_id, city, min_business_amount, max_economy_amount
from airports a 
join flights f on a.airport_code = f.arrival_airport
join cte using (flight_id)
join cte2 using (flight_id)
where min_business_amount < max_economy_amount

----------------------------------------------------------------------------------------------------------
--- ������� 8. (4792 ������)
-- ����� ������ �������� ��� ������ ������?
-- � ������� ����������� ������ ���� ������������:  
-- 		1. ��������� ������������ � ����������� FROM
--		2. �������������� ��������� ������������� (���� �������� �����������, �� ��� �������������)
-- 		3. �������� EXCEPT

-- �������: 
-- 1. ������� ����������� ������������� � ������������ �������� ������ ���������: 
--    ����� ������� "flights" � ��������� ��������� ������ ��������.
--    ����� ��������� ��������� ���������� ��������.
-- 	  ��������� � ������������� ����������� ������ ������� � ��������.
-- 2. ������ ��������� ������������ ������� �� ����������� "airports".
-- 3. � ������� ��������� EXCEPT ������� �� ��������� ������������ ������� ����, ����������� � ���������� � �������������.
-- 4. ������� ����, ��� ������ ������ � ���������� ���������, � ����� ����� � �������� �����������, ��� �������.

create view direct_flights_cities as
	select a.city as departure_city, a2.city as arrival_city
	from flights f
	join airports a on departure_airport = airport_code
	join airports a2 on arrival_airport = a2.airport_code 

select a1.city as departure_city, a2.city as arrival_city
from airports a1, airports a2
where a1.city != a2.city and a1.city < a2.city
EXCEPT
	select * from direct_flights_cities
order by departure_city, arrival_city

select count (departure_city)
from (select a1.city as departure_city, a2.city as arrival_city
from airports a1, airports a2
where a1.city != a2.city and a1.city > a2.city
EXCEPT
	select * from direct_flights_cities
order by departure_city, arrival_city )q


----------------------------------------------------------------------------------------------------------
--- ������� 9. 

-- ��������� ���������� ����� �����������, ���������� ������� �������, 
-- �������� � ���������� ������������ ���������� ���������  � ���������, ������������� ��� �����.
-- � ������� ����������� ������ ���� ������������:  
-- 		�������� RADIANS | �������� CASE 

-- �������: 
-- 1. ����� ������� "flights" � ��������� ��������� ������ � ������� ������������ �� ������� "airports".
-- 2. ��������� ���������� ����� ����������� � �� �� �������.
-- 3. ��������� ��������� ������ �� �� ������� "aircrafts".
-- 4. ��������� �������, ��� ������� �������� ���������� � ��������� ������ �� ������ ��������������.

select dep.airport_name, arr.airport_name, range,
	round (acos (sin(radians(dep.latitude))*sin(radians(arr.latitude)) + cos(radians(dep.latitude))*cos(radians(arr.latitude))*cos(radians(dep.longitude) - radians(arr.longitude)))*6371) as distance,
	case 
		when round (acos (sin(radians(dep.latitude))*sin(radians(arr.latitude)) + cos(radians(dep.latitude))*cos(radians(arr.latitude))*cos(radians(dep.longitude) - radians(arr.longitude)))*6371) < range then 'within_range'
		else 'out_of_range'
	end as range_zone
from flights f
join airports dep on departure_airport = dep.airport_code
join airports arr on arrival_airport = arr.airport_code 
join aircrafts using (aircraft_code)
where departure_airport < arrival_airport
group by dep.airport_code, dep.longitude, dep.latitude, arr.airport_code, arr.longitude, arr.latitude, range
order by dep.airport_name, arr.airport_name














