package attacks;

import utils.MathUtils;
import java.math.BigInteger;

/**
 * Pollard's Rho 算法求解离散对数
 * 用于求解离散对数问题: 给定 g^x ≡ h (mod p)，求x
 * 
 * 算法原理：
 * 使用伪随机函数生成序列，利用生日悖论找到碰撞
 * 将元素分为3个集合，使用不同的迭代函数
 * 
 * 优点：空间复杂度O(1)，适合处理较大的问题
 * 时间复杂度: O(√n)，但常数因子比BSGS大
 */
public class PollardRho {
    
    /**
     * 伪随机函数，将群元素映射到下一个元素
     * 同时跟踪指数：x_i = g^(a_i) * h^(b_i)
     */
    private static class SequenceElement {
        BigInteger value;  // x_i
        BigInteger aExp;   // a_i (g的指数)
        BigInteger bExp;   // b_i (h的指数)
        
        SequenceElement(BigInteger value, BigInteger aExp, BigInteger bExp) {
            this.value = value;
            this.aExp = aExp;
            this.bExp = bExp;
        }
        
        SequenceElement copy() {
            return new SequenceElement(value, aExp, bExp);
        }
    }
    
    /**
     * 伪随机迭代函数
     * 根据当前值分为3个区域，应用不同的操作
     */
    private static SequenceElement iterate(SequenceElement elem, BigInteger g, BigInteger h, 
                                          BigInteger p, BigInteger order) {
        BigInteger partition = elem.value.mod(BigInteger.valueOf(3));
        
        if (partition.equals(BigInteger.ZERO)) {
            // 区域0: x = h * x
            return new SequenceElement(
                elem.value.multiply(h).mod(p),
                elem.aExp,
                elem.bExp.add(BigInteger.ONE).mod(order)
            );
        } else if (partition.equals(BigInteger.ONE)) {
            // 区域1: x = g * x
            return new SequenceElement(
                elem.value.multiply(g).mod(p),
                elem.aExp.add(BigInteger.ONE).mod(order),
                elem.bExp
            );
        } else {
            // 区域2: x = x^2
            return new SequenceElement(
                elem.value.multiply(elem.value).mod(p),
                elem.aExp.multiply(BigInteger.TWO).mod(order),
                elem.bExp.multiply(BigInteger.TWO).mod(order)
            );
        }
    }
    
    /**
     * 求解离散对数
     * @param g 生成元
     * @param h 目标值 (g^x ≡ h (mod p))
     * @param p 模数（素数）
     * @param order 群的阶（通常是p-1）
     * @return x 使得 g^x ≡ h (mod p)
     */
    public static BigInteger solve(BigInteger g, BigInteger h, BigInteger p, BigInteger order) {
        return solve(g, h, p, order, false);
    }
    
    /**
     * 求解离散对数（带静默模式）
     * @param g 生成元
     * @param h 目标值 (g^x ≡ h (mod p))
     * @param p 模数（素数）
     * @param order 群的阶（通常是p-1）
     * @param silent 是否静默模式（不打印详细信息）
     * @return x 使得 g^x ≡ h (mod p)
     */
    public static BigInteger solve(BigInteger g, BigInteger h, BigInteger p, BigInteger order, boolean silent) {
        if (!silent) {
            System.out.println("\n========== Pollard's Rho Algorithm ==========");
            System.out.println("Problem: Solve g^x ≡ h (mod p)");
            System.out.println("g = " + g);
            System.out.println("h = " + h);
            System.out.println("p = " + p);
            System.out.println("order = " + order);
        }
        
        long startTime = System.currentTimeMillis();
        
        // 尝试最多30次，每次使用不同的初始值（对于安全素数，成功率约50%，30次几乎必成功）
        int maxAttempts = silent ? 5 : 30;  // 静默模式下只尝试5次
        for (int attempt = 1; attempt <= maxAttempts; attempt++) {
            if (!silent && attempt > 1) {
                System.out.println("\nAttempt " + attempt + " (using different initial value)...");
            }
            
            BigInteger result = solveAttempt(g, h, p, order, attempt, startTime, silent);
            if (result != null) {
                return result;
            }
            
            if (!silent && attempt < maxAttempts) {
                System.out.println("Retrying...");
            }
        }
        
        if (!silent) {
            long endTime = System.currentTimeMillis();
            System.out.println("\nFailed after " + maxAttempts + " attempts");
            System.out.println("Possible cause: order contains small factors, modular inverse doesn't exist");
            System.out.println("Suggest using BSGS or Pohlig-Hellman algorithms");
            System.out.println("Total time: " + (endTime - startTime) + " ms");
        }
        return null;
    }
    
    /**
     * 单次尝试求解
     */
    private static BigInteger solveAttempt(BigInteger g, BigInteger h, BigInteger p, BigInteger order, 
                                          int attempt, long startTime, boolean silent) {
        
        // 使用不同的初始值：attempt=1 时用标准初始值，之后用随机初始值
        SequenceElement tortoise;
        if (attempt == 1) {
            tortoise = new SequenceElement(BigInteger.ONE, BigInteger.ZERO, BigInteger.ZERO);
        } else {
            // 随机选择初始值: x_0 = g^a * h^b
            BigInteger randA = MathUtils.randomBigInteger(BigInteger.ZERO, order);
            BigInteger randB = MathUtils.randomBigInteger(BigInteger.ZERO, order);
            BigInteger initValue = MathUtils.modPow(g, randA, p).multiply(MathUtils.modPow(h, randB, p)).mod(p);
            tortoise = new SequenceElement(initValue, randA, randB);
        }
        SequenceElement hare = tortoise.copy();
        
        if (!silent && attempt == 1) {
            System.out.println("\nUsing Floyd's cycle detection (tortoise-hare) to find collision...");
        }
        
        int iterations = 0;
        // 目标最多打印20次：interval ≈ ceil(√order / 20)
        int printEvery;
        try {
            BigInteger approxSqrt = MathUtils.sqrt(order);
            BigInteger interval = approxSqrt.add(BigInteger.valueOf(19)).divide(BigInteger.valueOf(20));
            if (interval.compareTo(BigInteger.ONE) < 0) interval = BigInteger.ONE;
            printEvery = interval.intValue();
        } catch (Exception e) {
            printEvery = 10000; // 兜底
        }
        while (true) {
            // 龟走一步
            tortoise = iterate(tortoise, g, h, p, order);
            // 兔走两步
            hare = iterate(hare, g, h, p, order);
            hare = iterate(hare, g, h, p, order);
            
            iterations++;
            
            // Print detailed progress only on first attempt
            if (!silent && attempt == 1 && iterations % printEvery == 0) {
                System.out.println("  Iterations: " + iterations);
            }
            
            // 检查是否碰撞
            if (tortoise.value.equals(hare.value)) {
                if (!silent) {
                    System.out.println("\nCollision found! Iterations: " + iterations);
                    System.out.println("tortoise: g^" + tortoise.aExp + " * h^" + tortoise.bExp);
                    System.out.println("hare: g^" + hare.aExp + " * h^" + hare.bExp);
                }
                
                // g^a1 * h^b1 ≡ g^a2 * h^b2 (mod p)
                // h^(b1-b2) ≡ g^(a2-a1) (mod p)
                // g^(x*(b1-b2)) ≡ g^(a2-a1) (mod p)
                // x*(b1-b2) ≡ (a2-a1) (mod order)
                // x ≡ (a2-a1) * (b1-b2)^(-1) (mod order)
                
                BigInteger numerator = hare.aExp.subtract(tortoise.aExp).mod(order);
                BigInteger denominator = tortoise.bExp.subtract(hare.bExp).mod(order);
                
                if (!silent) {
                    System.out.println("\nSolving equation: x ≡ " + numerator + " * " + denominator + "^(-1) (mod " + order + ")");
                }
                
                if (denominator.equals(BigInteger.ZERO)) {
                    if (!silent) {
                        System.out.println("Warning: Denominator is 0, need to retry with different initial value");
                    }
                    return null;
                }
                
                // Check if modular inverse exists: gcd(denominator, order) must be 1
                BigInteger gcdVal = denominator.gcd(order);
                if (!gcdVal.equals(BigInteger.ONE)) {
                    if (!silent) {
                        System.out.println("\nModular inverse doesn't exist: gcd(" + denominator + ", " + order + ") = " + gcdVal + " ≠ 1");
                        if (attempt == 1) {
                            System.out.println("This is normal failure for Pollard's Rho probabilistic algorithm (~1-5% probability)");
                        }
                    }
                    return null;  // Return null, outer loop will retry
                }
                
                try {
                    BigInteger x = numerator.multiply(MathUtils.modInverse(denominator, order)).mod(order);
                    
                    if (!silent) {
                        long endTime = System.currentTimeMillis();
                        System.out.println("\nFound solution!" + (attempt > 1 ? " (succeeded on attempt " + attempt + ")" : ""));
                        System.out.println("x = " + x);
                        System.out.println("Verification: g^x mod p = " + MathUtils.modPow(g, x, p));
                        System.out.println("Expected h = " + h);
                        System.out.println("Time: " + (endTime - startTime) + " ms");
                    }
                    
                    return x;
                } catch (Exception e) {
                    if (!silent) {
                        System.out.println("\nModular inverse computation failed: " + e.getMessage());
                    }
                    return null;  // Return null, outer loop will retry
                }
            }
            
            // Prevent infinite loop
            if (iterations > 10000000) {
                if (!silent) {
                    System.out.println("\nExceeded maximum iterations, algorithm terminated");
                }
                return null;
            }
        }
    }
    
    /**
     * 简化版本：假设order = p - 1
     */
    public static BigInteger solve(BigInteger g, BigInteger h, BigInteger p) {
        return solve(g, h, p, p.subtract(BigInteger.ONE));
    }
}

