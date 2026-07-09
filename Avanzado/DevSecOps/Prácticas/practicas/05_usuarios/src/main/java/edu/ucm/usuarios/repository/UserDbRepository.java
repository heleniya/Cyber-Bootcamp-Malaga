package edu.ucm.usuarios.repository;

import edu.ucm.usuarios.model.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserDbRepository extends JpaRepository<User, Integer> {

    Optional<User> findUserById(int id);

    User findUserByNombre(String nombre);
}
