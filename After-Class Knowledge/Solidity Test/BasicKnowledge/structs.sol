// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title StructsAndStorage
 * @notice 演示结构体的使用以及 storage 和 memory 关键字的区别。
 */
contract StructsAndStorage { // 规范化合约名
    
    /**
     * @notice 汽车信息结构体。
     */
    struct Car { // 规范化结构体名
        string model;
        uint256 year; // 明确类型 uint256
        address owner;
    }

    // 状态变量（Storage）
    Car public myCar; 
    Car[] public cars; 
    mapping (address => Car[]) public carsByOwner;
    mapping (address => Car) public carByAddress; // 规范化变量名

    /**
     * @notice 创建新的 Car 结构体并存储到数组和映射中。
     */
    function createCars() external { // 规范化函数名
        // Car memory：创建在内存中，不占用存储槽
        Car memory newCar1 = Car({model: "Tesla Model S", year: 2022, owner: msg.sender});
        Car memory newCar2 = Car("Lamborghini", 2020, msg.sender);

        // 从 memory 复制到 storage
        cars.push(newCar1);
        cars.push(newCar2);
        
        // 注意：将一个 storage 数组赋值给另一个 storage 数组（如 carsByOwner[msg.sender]），
        // 默认是**深拷贝**。
        carsByOwner[msg.sender] = cars;
    }

    /**
     * @notice 演示 storage 引用和 memory 拷贝的区别。
     * @dev 对 storage 引用 (newCars) 的修改会影响状态变量，对 memory 拷贝 (myCars) 的修改不会。
     * @return storageRefArray 存储引用的数组。
     * @return memoryCopyArray 内存拷贝的数组。
     */
    function viewStorageAndMemory() external view returns (Car[] memory storageRefArray, Car[] memory memoryCopyArray) {
        // storage 引用：newCars 指向状态变量 carsByOwner[msg.sender] 的实际存储位置
        Car[] storage newCars = carsByOwner[msg.sender]; 
        
        // memory 拷贝：myCars 是 newCars 的一个独立的副本
        Car[] memory myCars = carsByOwner[msg.sender]; 
        
        // delete myCars[0]; // 此操作只影响 memory 副本，不影响 newCars 和状态变量

        return (newCars, myCars);
    }

    /**
     * @notice 演示如何使用 storage 引用来直接修改映射中的结构体状态变量。
     */
    function updateCarInMapping() external { // 规范化函数名
        // 1. 直接赋值创建并存储结构体
        carByAddress[msg.sender] = Car({model: "Land Rover", year: 1080, owner: msg.sender});
        
        // 2. 创建 storage 引用，直接修改状态变量
        Car storage carRef = carByAddress[msg.sender]; 
        carRef.year = 1024; // **此修改直接更新了状态变量 carByAddress[msg.sender]**

        // 3. 创建 memory 拷贝，修改不影响状态变量
        Car memory carCopy = carByAddress[msg.sender]; 
        carCopy.year = 9999; // 此修改只影响 memory 副本
    }
}