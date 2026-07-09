package edu.ucm.productos.service;


import edu.ucm.productos.exception.NotFoundProductException;
import edu.ucm.productos.model.Product;
import edu.ucm.productos.model.StockDto;
import edu.ucm.productos.repository.ProductRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ProductService {

    private ProductRepository productRepository;

    public ProductService(ProductRepository productRepository) {
        this.productRepository = productRepository;
    }

    public List<Product>  getAllProducts(String categoria, Double precioMin, Double precioMax) {
        return productRepository.findAllProductsByFilters(categoria, precioMin, precioMax);
    }

    public Product createProduct(Product product) {
        product.setId(null);
        return productRepository.save(product);
    }


    public Product updateProduct(Product product) {
        Product productById = getProductById(product.getId());

        productById.setActivo(product.getActivo());
        productById.setStock(product.getStock());
        productById.setCategoria(product.getCategoria());
        productById.setNombre(product.getNombre());
        productById.setDescripcion(product.getDescripcion());
        productById.setPrecio(product.getPrecio());

        return productRepository.save(productById);
    }

    public StockDto getStock(Integer id) {
        Product productById = getProductById(id);
        return new StockDto(productById.getId(), productById.getStock());
    }


    private Product getProductById(Integer id) {
       return productRepository.findProductById(id)
               .orElseThrow(()-> new NotFoundProductException("Producto no encontrado con id: " +id));

    }


}
