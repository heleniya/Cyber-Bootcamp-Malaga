package edu.ucm.usuarios.service;

import com.opencsv.CSVWriter;
import edu.ucm.usuarios.exception.NotFoundException;
import edu.ucm.usuarios.model.User;
import edu.ucm.usuarios.repository.UserDbRepository;
import edu.ucm.usuarios.repository.UserRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.crossstore.ChangeSetPersister;
import org.springframework.stereotype.Service;

import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class UserService {

    UserRepository userRepository;
    UserDbRepository userDbRepository;

    @Value("${user_csv_path}")
    private String csvPath;

    public UserService(UserDbRepository userDbRepository) {
        this.userRepository = new UserRepository();
        this.userDbRepository = userDbRepository;
    }

    public List<User> getUsers() {
        List<User> usersList = new ArrayList<>();

        User user = new User();
        user.setId(1);
        user.setNombre("admin");
        user.setApellido("apellido");
        user.setEmail("email@email.com");

        usersList.add(user);

        return usersList;
    }

    public List<User> getAllUsers() {
        return  userDbRepository.findAll();
    }

    public List<User> getUserFromRepo() {

        return userRepository.getUsers();
    }

    public User createUSer(User user) {
        // llamar el metodo del repository para guardar en la lista
//        userRepository.saveUser(user);
        user.setId(null);
        userDbRepository.save(user);
        return user;
    }

    public User updateUser(User user) {
        // llamar el metodo del repository que actualiza la lista
//        return userRepository.updateUser(user);
        // retornar el usuario actualizado

        User userById = getUserById(user.getId());

        userById.setNombre(user.getNombre());
        userById.setApellido(user.getApellido());
        userById.setEmail(user.getEmail());

        return userDbRepository.save(userById);


    }

    public User getUserById(Integer id) {


        // llamar metodo del repository   que devuelve el usuario i
        return userDbRepository.findUserById(id)
                .orElseThrow(()->new NotFoundException("Usuario no encontrado"));
    }

    public Boolean deleteUserById(Integer id) {
        // llamar metodo del repository
        User userById = getUserById(id);
        userDbRepository.delete(userById);
        return true;

    }

    public User createUserCsv(User user) throws IOException {
        String[] userString = {user.getNombre(), user.getApellido(), user.getEmail()};

        try (CSVWriter writer = new CSVWriter(new FileWriter(csvPath, true))) {
//            for (String[] line : lines) {
            writer.writeNext(userString);
//            }

            return user;
        }
    }

}


















