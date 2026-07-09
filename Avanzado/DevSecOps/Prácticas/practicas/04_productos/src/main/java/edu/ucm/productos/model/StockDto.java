package edu.ucm.productos.model;

public class StockDto {

    private Integer id;
    private Integer stock;

    public StockDto() {
    }

    public StockDto(Integer id, Integer stock) {
        this.id = id;
        this.stock = stock;
    }

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Integer getStock() {
        return stock;
    }

    public void setStock(Integer stock) {
        this.stock = stock;
    }
}
