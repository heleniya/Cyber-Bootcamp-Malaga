package edu.ucm.usuarios.controller;

import edu.ucm.usuarios.exception.CsvIOException;
import edu.ucm.usuarios.model.User;
import edu.ucm.usuarios.service.UserService;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.util.List;

@RestController
public class UserController {

    UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/users")
    public List<User> getUsers() {
//        List<User> users = userService.getUsers();
        List<User> users = userService.getAllUsers();
        return users;
    }

    @Deprecated
    @GetMapping("/users-repo")
    public List<User> getUserFromRepo() {
        List<User> users = userService.getUserFromRepo();
        return users;
    }

    @PostMapping("/create")
    public User createUser(@RequestBody User user) {
        // llamar el metodo de guardado de service
        return userService.createUSer(user);
        //retornar la respuesta
    }

    @PutMapping("/update")
    public User updateUser(@RequestBody User user) {
        //llamar el metodo de actualizar de service
        return userService.updateUser(user);
        //retornar respuesta
    }

    @GetMapping("/users/{id}")
    public User getUser(@PathVariable Integer id) {
        // llamar metodo del service
        return userService.getUserById(id);
    }


    @DeleteMapping("/user/{id}")
    public Boolean deleteUser(@PathVariable Integer id) {
        // llamar metodo del service
        return userService.deleteUserById(id);

    }

    @PostMapping("/create-user-csv")
    public User  createUserCsv(@RequestBody User user) {
        try {
            return userService.createUserCsv(user);
        } catch (IOException e) {
            throw new CsvIOException("Hubo un error escribiendo el csv");
        }
    }

}
