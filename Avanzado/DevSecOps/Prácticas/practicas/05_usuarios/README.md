# Usuarios Spring Boot Project

Este proyecto permite crear, actualizar, eliminar y consultar usuarios
## Prerrequisitos

Antes de correr la aplicacion asegurate de cumplir con los prerrequisitos

- **Java 17** (to run the project)
- **Maven** (for building the project)
- **MySQL**

*Nota*: Debe estar configurado el usuario y contraseña de la base de datos, adicionalmente debe existir la base de datos clientes y la tabla **usuarios** con los siguientes campos:


| Campo      | Tipo      | Restricciones               |
|------------|-----------|-----------------------------|
| `id`       | `BIGINT`  | Primary Key, Auto Increment |
| `nombre`   | `VARCHAR` |                             |
| `apellido` | `VARCHAR` |                             |
| `email`    | `VARCHAR` |                             |


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
java -jar target/usuarios.jar
```


Correr la aplicacion sin generar el jar

```shell script 
 mvn spring-boot:run
```

## docs
Una vez iniciado el proyecto se puede ir a la pagina de documentacion para probar las apis

[url swagger](http://localhost:8080/users/swagger-ui/index.html)