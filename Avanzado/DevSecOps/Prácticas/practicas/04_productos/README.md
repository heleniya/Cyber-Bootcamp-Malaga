# Usuarios Spring Boot Project

Este proyecto permite crear, actualizar, eliminar y consultar productos
## Prerrequisitos

Antes de correr la aplicacion asegurate de cumplir con los prerrequisitos

- **Java 17** (to run the project)
- **Maven** (for building the project)
- **MySQL o Postgresql**

*Nota*: Debe estar configurado el usuario y contraseña de la base de datos, adicionalmente debe existir la base de datos postgres y la tabla **productos** con los siguientes campos:


| Field             | Type    |
|-------------------|---------|
| id  (primary key) | Serial  |
| nombre            | String  |
| descripcion       | String  |
| precio            | Double  |
| categoria         | String  |
| stock             | Integer |
| activo            | Boolean |


Luego abrir el **application.properties** y reemplazar los valores de las propiedades de username y password

- spring.datasource.username=XXXXXXXXXXXXXX
- spring.datasource.password=YYYYYYYYYYYYYY


## Comandos

construir el proyecto

```shell script 
mvn clean install
```

Correr la aplicacion

```shell script 
java -jar target/productos.jar
```


Correr la aplicacion sin generar el jar

```shell script 
 mvn spring-boot:run
```

## docs
Una vez iniciado el proyecto se puede ir a la pagina de documentacion para probar las apis

[url swagger](http://localhost:8081/products/swagger-ui/index.html)