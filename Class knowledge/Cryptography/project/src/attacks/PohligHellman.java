package attacks;

import utils.MathUtils;
import java.math.BigInteger;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Pohlig-Hellman 算法
 * 专门用于攻击"弱参数"：当群的阶有许多小素因子时特别有效
 * 
 * 算法原理：
 * 如果 n = p1^e1 * p2^e2 * ... * pk^ek
 * 可以将DLP问题分解为多个模pi^ei的子问题
 * 然后使用中国剩余定理（CRT）合并结果
 * 
 * 这就是为什么在密码学中要选择"强素数"p，使得p-1有大素因子
 */
public class PohligHellman {
    
    /**
     * 求解离散对数（当order有小素因子时）
     * @param g 生成元
     * @param h 目标值
     * @param p 模数
     * @param order 群的阶
     * @return x 使得 g^x ≡ h (mod p)
     */
    public static BigInteger solve(BigInteger g, BigInteger h, BigInteger p, BigInteger order) {
        System.out.println("\n========== Pohlig-Hellman Algorithm ==========");
        System.out.println("Problem: Solve g^x ≡ h (mod p)");
        System.out.println("g = " + g);
        System.out.println("h = " + h);
        System.out.println("p = " + p);
        System.out.println("order = " + order);
        
        long startTime = System.currentTimeMillis();
        
        // Step 1: Factorize order
        System.out.println("\nStep 1: Factorizing order...");
        List<BigInteger> factors = MathUtils.factorize(order);
        System.out.println("Prime factorization: " + factors);
        
        // 统计每个素因子的幂次
        Map<BigInteger, Integer> factorPowers = new HashMap<>();
        for (BigInteger factor : factors) {
            factorPowers.put(factor, factorPowers.getOrDefault(factor, 0) + 1);
        }
        
        System.out.println("\nPrime factors and their powers:");
        int printed = 0;
        int maxPrint = 20; // Maximum 20 lines output
        for (Map.Entry<BigInteger, Integer> entry : factorPowers.entrySet()) {
            if (printed < maxPrint) {
                System.out.println("  " + entry.getKey() + "^" + entry.getValue());
            }
            printed++;
        }
        if (printed > maxPrint) {
            System.out.println("  ... Total " + printed + " factors, remaining output omitted");
        }
        
        // Step 2: Solve subproblems for each prime power
        System.out.println("\nStep 2: Solving subproblems...");
        BigInteger[] moduli = new BigInteger[factorPowers.size()];
        BigInteger[] remainders = new BigInteger[factorPowers.size()];
        
        int idx = 0;
        for (Map.Entry<BigInteger, Integer> entry : factorPowers.entrySet()) {
            BigInteger prime = entry.getKey();
            int exponent = entry.getValue();
            BigInteger primePower = prime.pow(exponent);
            
            int maxSubPrint = 20; // Limit subproblem output to 20 lines
            if (idx < maxSubPrint) {
                System.out.println("\n  Subproblem " + (idx + 1) + ": mod " + prime + "^" + exponent + " = " + primePower);
            } else if (idx == maxSubPrint) {
                System.out.println("\n  ... Many subproblems, remaining progress output omitted");
            }
            
            // 求解 x mod (prime^exponent)
            BigInteger xi = solveForPrimePower(g, h, p, order, prime, exponent);
            
            moduli[idx] = primePower;
            remainders[idx] = xi;
            
            if (idx < maxSubPrint) {
                System.out.println("    x ≡ " + xi + " (mod " + primePower + ")");
            }
            idx++;
        }
        
        // Step 3: Combine using Chinese Remainder Theorem
        System.out.println("\nStep 3: Combining results using Chinese Remainder Theorem...");
        BigInteger x = chineseRemainderTheorem(remainders, moduli);
        
        long endTime = System.currentTimeMillis();
        System.out.println("\nFound solution!");
        System.out.println("x = " + x);
        System.out.println("Verification: g^x mod p = " + MathUtils.modPow(g, x, p));
        System.out.println("Expected h = " + h);
        System.out.println("Time: " + (endTime - startTime) + " ms");
        
        return x;
    }
    
    /**
     * 求解 x mod p^e 的子问题
     * 使用逐位确定法
     */
    private static BigInteger solveForPrimePower(BigInteger g, BigInteger h, BigInteger p,
                                                  BigInteger order, BigInteger prime, int e) {
        BigInteger x = BigInteger.ZERO;
        BigInteger gamma = MathUtils.modPow(g, order.divide(prime), p);  // γ = g^(n/p)
        
        for (int k = 0; k < e; k++) {
            // 计算 h_k = h * g^(-x) mod p
            BigInteger hk = h.multiply(MathUtils.modPow(g, x.negate().mod(order), p)).mod(p);
            
            // 计算 hk^(n/p^{k+1}) mod p
            BigInteger exp = order.divide(prime.pow(k + 1));
            BigInteger delta = MathUtils.modPow(hk, exp, p);
            
            // 求解 γ^{x_k} ≡ δ (mod p)，其中 x_k < p
            BigInteger xk = discreteLogSmall(gamma, delta, p, prime);
            
            // 更新 x = x + x_k * p^k
            x = x.add(xk.multiply(prime.pow(k)));
            
            System.out.println("      Digit " + k + ": x_" + k + " = " + xk);
        }
        
        return x.mod(prime.pow(e));
    }
    
    /**
     * 求解小的离散对数问题（暴力搜索或BSGS）
     * 求解 g^x ≡ h (mod p)，其中 0 ≤ x < limit
     */
    private static BigInteger discreteLogSmall(BigInteger g, BigInteger h, BigInteger p, BigInteger limit) {
        // 特殊情况
        if (h.equals(BigInteger.ONE)) {
            return BigInteger.ZERO;
        }
        if (g.equals(h)) {
            return BigInteger.ONE;
        }
        
        // 如果limit较小，使用暴力搜索
        if (limit.compareTo(BigInteger.valueOf(100000)) <= 0) {
            BigInteger current = BigInteger.ONE;
            for (BigInteger i = BigInteger.ZERO; i.compareTo(limit) < 0; i = i.add(BigInteger.ONE)) {
                if (current.equals(h)) {
                    return i;
                }
                current = current.multiply(g).mod(p);
            }
            return BigInteger.ZERO;
        }
        
        // 否则使用Baby-step Giant-step
        BigInteger m = MathUtils.sqrt(limit).add(BigInteger.ONE);
        
        // Baby step
        Map<BigInteger, BigInteger> table = new HashMap<>();
        BigInteger gPower = BigInteger.ONE;
        for (BigInteger j = BigInteger.ZERO; j.compareTo(m) < 0; j = j.add(BigInteger.ONE)) {
            table.put(gPower, j);
            gPower = gPower.multiply(g).mod(p);
        }
        
        // Giant step
        BigInteger gInvM = MathUtils.modPow(MathUtils.modInverse(g, p), m, p);
        BigInteger gamma = h;
        for (BigInteger i = BigInteger.ZERO; i.compareTo(m) < 0; i = i.add(BigInteger.ONE)) {
            if (table.containsKey(gamma)) {
                return i.multiply(m).add(table.get(gamma));
            }
            gamma = gamma.multiply(gInvM).mod(p);
        }
        
        return BigInteger.ZERO;
    }
    
    /**
     * 中国剩余定理
     * 求解 x ≡ a_i (mod m_i)
     */
    private static BigInteger chineseRemainderTheorem(BigInteger[] remainders, BigInteger[] moduli) {
        if (remainders.length != moduli.length) {
            throw new IllegalArgumentException("余数和模数数组长度必须相同");
        }
        
        // 计算所有模数的乘积
        BigInteger M = BigInteger.ONE;
        for (BigInteger mod : moduli) {
            M = M.multiply(mod);
        }
        
        BigInteger result = BigInteger.ZERO;
        
        for (int i = 0; i < remainders.length; i++) {
            BigInteger Mi = M.divide(moduli[i]);
            BigInteger yi = MathUtils.modInverse(Mi, moduli[i]);
            result = result.add(remainders[i].multiply(Mi).multiply(yi));
        }
        
        return result.mod(M);
    }
    
    /**
     * 简化版本
     */
    public static BigInteger solve(BigInteger g, BigInteger h, BigInteger p) {
        return solve(g, h, p, p.subtract(BigInteger.ONE));
    }
}
