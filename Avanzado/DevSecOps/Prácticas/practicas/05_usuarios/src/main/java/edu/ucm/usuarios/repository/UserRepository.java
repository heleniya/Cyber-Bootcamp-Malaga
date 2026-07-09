package edu.ucm.usuarios.repository;

import edu.ucm.usuarios.model.User;

import java.util.ArrayList;
import java.util.List;

public class UserRepository {

    List<User> users;

    public UserRepository() {
        users = new ArrayList<>();
    };

    public void saveUser(User user) {

        // persistir en la base de datos
        users.add(user);

    }

    public List<User> getUsers() {
        return users;
    }

    public User updateUser(User user) {
        //reemplazar el elemento i de la lista

        Integer userPosition = iterateUsersById(user.getId());

        users.set(userPosition, user);

        return users.get(userPosition);
        // obtener el elmento

        // hacer un set de los campos que queremos actualizar

       // hacer un set de la lista

        //retornar el elemento actualizado
    }


    public User getUserById(Integer id){
        // obtener el elemento i de la lista
       Integer userPosition = iterateUsersById(id);

      return users.get(userPosition);
    }

    public Boolean deleteUser(Integer id) {
        // llamar metodo del repository
       Integer userPosition = iterateUsersById(id);
       if (userPosition == null)
           return false;

       users.remove((int)userPosition);
       return true;
    }

    private Integer iterateUsersById(Integer id) {
        for (int  i = 0; i<users.size(); i++) {
            if (users.get(i).getId() == id)
                return i;
        }
        return null;
    }


}




