package edu.ucm.productos.controller;


import edu.ucm.productos.model.Product;
import edu.ucm.productos.model.StockDto;
import edu.ucm.productos.service.ProductService;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
public class ProductController {

    private ProductService productService;

    public ProductController(ProductService productService) {
        this.productService = productService;
    }

    @GetMapping("/products")
    public List<Product> getProducts(@RequestParam(required = false) String categoria,
                                     @RequestParam(required = false) Double precioMin,
                                     @RequestParam(required = false) Double precioMax) {

        return productService.getAllProducts(categoria, precioMin, precioMax);
    }

    @PostMapping("/create")
    public Product createProduct(@RequestBody Product product) {

        return  productService.createProduct(product);
    }

    @PutMapping("/update")
    public Product updateProduct(@RequestBody Product product) {
        return productService.updateProduct(product);
    }

    @GetMapping("/stock/{id}/")
    public StockDto getStock(@PathVariable Integer id) {
        return productService.getStock(id);
    }


}
