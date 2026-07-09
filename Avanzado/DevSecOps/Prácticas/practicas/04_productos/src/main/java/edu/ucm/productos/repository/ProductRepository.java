package edu.ucm.productos.repository;

import edu.ucm.productos.model.Product;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

public interface ProductRepository extends JpaRepository<Product, Integer> {

    @Query("SELECT p FROM Product p WHERE " +
            "    (:categoria IS NULL OR p.categoria = :categoria) " +
            "                              AND (:precioMin IS NULL OR p.precio >= :precioMin) " +
            "                              AND (:precioMax IS NULL OR p.precio <= :precioMax) ")
    List<Product> findAllProductsByFilters(String categoria, Double precioMin, Double precioMax);

    Optional<Product> findProductById(Integer id);
}
