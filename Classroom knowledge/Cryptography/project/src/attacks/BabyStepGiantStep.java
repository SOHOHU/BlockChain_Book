package attacks;

import utils.MathUtils;
import java.math.BigInteger;
import java.util.HashMap;
import java.util.Map;

/**
 * Baby-step Giant-step 算法
 * 用于求解离散对数问题: 给定 g^x ≡ h (mod p)，求x
 * 
 * 算法原理：
 * 1. 设 x = im + j，其中 m = ⌈√n⌉，n是群的阶（通常是p-1）
 * 2. Baby step: 计算并存储 g^j mod p，其中 j = 0,1,...,m-1
 * 3. Giant step: 计算 g^(-m) mod p，然后检查 h*(g^(-m))^i 是否在Baby step表中
 * 
 * 时间复杂度: O(√n)
 * 空间复杂度: O(√n)
 */
public class BabyStepGiantStep {
    // 目标最多打印20次：interval = ceil(total/20)，且至少为1
    private static BigInteger chooseProgressInterval(BigInteger totalSteps) {
        if (totalSteps.compareTo(BigInteger.ZERO) <= 0) return BigInteger.ONE;
        BigInteger twenty = BigInteger.valueOf(20);
        BigInteger interval = totalSteps.add(twenty.subtract(BigInteger.ONE)).divide(twenty);
        if (interval.compareTo(BigInteger.ONE) < 0) interval = BigInteger.ONE;
        return interval;
    }
    
    /**
     * 求解离散对数
     * @param g 生成元
     * @param h 目标值 (g^x ≡ h (mod p))
     * @param p 模数（素数）
     * @param order 群的阶（通常是p-1）
     * @return x 使得 g^x ≡ h (mod p)，如果未找到返回null
     */
    public static BigInteger solve(BigInteger g, BigInteger h, BigInteger p, BigInteger order) {
        System.out.println("\n========== Baby-step Giant-step Algorithm ==========");
        System.out.println("Problem: Solve g^x ≡ h (mod p)");
        System.out.println("g = " + g);
        System.out.println("h = " + h);
        System.out.println("p = " + p);
        System.out.println("order = " + order);
        
        long startTime = System.currentTimeMillis();
        
        // 计算 m = ⌈√order⌉
        BigInteger m = MathUtils.sqrt(order).add(BigInteger.ONE);
        System.out.println("\nBaby step size m = ⌈√order⌉ = " + m);
        
        // Baby step: Build table {g^j mod p : j} for j = 0,1,...,m-1
        System.out.println("\nPhase 1: Baby steps - building hash table...");
        Map<BigInteger, BigInteger> table = new HashMap<>();
        BigInteger gPower = BigInteger.ONE;
        BigInteger babyInterval = chooseProgressInterval(m);
        
        for (BigInteger j = BigInteger.ZERO; j.compareTo(m) < 0; j = j.add(BigInteger.ONE)) {
            table.put(gPower, j);
            gPower = gPower.multiply(g).mod(p);
            
            if (j.compareTo(BigInteger.ZERO) > 0 && j.mod(babyInterval).equals(BigInteger.ZERO)) {
                System.out.println("  Computed " + j + " baby steps...");
            }
        }
        System.out.println("Baby steps complete, table size: " + table.size());
        
        // Giant step: Calculate g^(-m) mod p
        System.out.println("\nPhase 2: Giant steps - searching for match...");
        BigInteger gInvM = MathUtils.modInverse(g, p);
        gInvM = MathUtils.modPow(gInvM, m, p);
        System.out.println("g^(-m) mod p = " + gInvM);
        
        // 检查 h * (g^(-m))^i
        BigInteger gamma = h;
        BigInteger giantInterval = babyInterval; // 与baby相同量级的间隔
        for (BigInteger i = BigInteger.ZERO; i.compareTo(m) < 0; i = i.add(BigInteger.ONE)) {
            if (table.containsKey(gamma)) {
                BigInteger j = table.get(gamma);
                BigInteger x = i.multiply(m).add(j);
                
                long endTime = System.currentTimeMillis();
                System.out.println("\nFound solution!");
                System.out.println("x = " + x);
                System.out.println("Verification: g^x mod p = " + MathUtils.modPow(g, x, p));
                System.out.println("Expected h = " + h);
                System.out.println("Time: " + (endTime - startTime) + " ms");
                
                return x;
            }
            gamma = gamma.multiply(gInvM).mod(p);
            
            if (i.compareTo(BigInteger.ZERO) > 0 && i.mod(giantInterval).equals(BigInteger.ZERO)) {
                System.out.println("  Attempted " + i + " giant steps...");
            }
        }
        
        long endTime = System.currentTimeMillis();
        System.out.println("\nNo solution found");
        System.out.println("Time: " + (endTime - startTime) + " ms");
        
        return null;
    }
    
    /**
     * 简化版本：假设order = p - 1
     */
    public static BigInteger solve(BigInteger g, BigInteger h, BigInteger p) {
        return solve(g, h, p, p.subtract(BigInteger.ONE));
    }
}

