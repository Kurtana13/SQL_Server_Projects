create database KhashuriRailway

go

use KhashuriRailway

go

Create table TrainRoute(
route_id int primary key,
start_point varchar(50) not null,
end_point varchar(50) not null,
route_length int not null,
);

go

Create table Station(
station_name varchar(50),
station_location varchar(50) not null,
primary key(station_name)
)

go


create table TrainRouteStation(
route_id int,
station_name varchar(50),
constraint PK_TrainRouteStation primary key(route_id,station_name),
constraint FK_TrainRouteStation_TrainRoute foreign key(route_id) references TrainRoute(route_id),
constraint FK_TrainRouteStation_Station foreign key(station_name) references Station(station_name)
);

go

create table Train(
train_id int,
carriagies int,
route_id int,
constraint PK_Train primary key(train_id),
constraint FK_Train_TrainRoute foreign key(route_id) references TrainRoute(route_id)
);

go

create table Customer(
customer_id int,
customer_name varchar(50),
customer_phone int not null,
customer_mail varchar(50) not null,
train_id int,
constraint PK_Customer primary key(customer_id),
constraint FK_Customer_Train foreign key(train_id) references Train(train_id)
);

go

create table Employee(
emp_id int,
emp_phone varchar(50) not null,
emp_salary int not null,
train_id int,
constraint PK_Employee primary key(emp_id),
constraint FK_Employee_Train foreign key(train_id) references Train(train_id)
)

go

create table Driver(
emp_id int,
vision_score int not null,
train_id int unique,
constraint PK_Driver primary key(emp_id),
constraint FK_Driver_Employee foreign key(emp_id) references Employee(emp_id),
constraint FK_Driver_Train foreign key(train_id) references Train(train_id)
)

go

create table Waiter(
emp_id int,
constraint PK_Waiter primary key(emp_id),
constraint FK_Waiter_Employee foreign key(emp_id) references Employee(emp_id)
)

go

create table WaiterSkills(
emp_id int,
skill varchar(50) not null,
constraint FK_WaiterSkills_Waiter foreign key(emp_id) references Waiter(emp_id)
)
