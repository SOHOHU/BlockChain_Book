package utils;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

/**
 * 数学工具类 - 提供密码学所需的基础数学运算
 */
public class MathUtils {
    
    private static final Random random = new Random();
    
    /**
     * 模幂运算: 计算 (base^exponent) mod modulus
     * 使用快速幂算法（平方-乘法）
     * 时间复杂度: O(log exponent)
     */
    public static BigInteger modPow(BigInteger base, BigInteger exponent, BigInteger modulus) {
        if (modulus.equals(BigInteger.ONE)) {
            return BigInteger.ZERO;
        }
        
        BigInteger result = BigInteger.ONE;
        base = base.mod(modulus);
        
        while (exponent.compareTo(BigInteger.ZERO) > 0) {
            // 如果指数是奇数，将当前base乘到结果中
            if (exponent.testBit(0)) {
                result = result.multiply(base).mod(modulus);
            }
            // 指数除以2，base平方
            exponent = exponent.shiftRight(1);
            base = base.multiply(base).mod(modulus);
        }
        
        return result;
    }
    
    /**
     * Miller-Rabin素性测试
     * 概率性算法，rounds越大准确率越高
     */
    public static boolean isProbablePrime(BigInteger n, int rounds) {
        if (n.compareTo(BigInteger.TWO) < 0) {
            return false;
        }
        if (n.equals(BigInteger.TWO) || n.equals(BigInteger.valueOf(3))) {
            return true;
        }
        if (n.mod(BigInteger.TWO).equals(BigInteger.ZERO)) {
            return false;
        }
        
        // 将 n-1 写成 2^r * d 的形式
        BigInteger d = n.subtract(BigInteger.ONE);
        int r = 0;
        while (d.mod(BigInteger.TWO).equals(BigInteger.ZERO)) {
            d = d.divide(BigInteger.TWO);
            r++;
        }
        
        // 进行rounds轮测试
        for (int i = 0; i < rounds; i++) {
            BigInteger a = randomBigInteger(BigInteger.TWO, n.subtract(BigInteger.TWO));
            BigInteger x = modPow(a, d, n);
            
            if (x.equals(BigInteger.ONE) || x.equals(n.subtract(BigInteger.ONE))) {
                continue;
            }
            
            boolean continueLoop = false;
            for (int j = 0; j < r - 1; j++) {
                x = x.multiply(x).mod(n);
                if (x.equals(n.subtract(BigInteger.ONE))) {
                    continueLoop = true;
                    break;
                }
            }
            
            if (!continueLoop) {
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * 生成指定位数的随机素数
     */
    public static BigInteger generatePrime(int bitLength, int certainty) {
        BigInteger prime;
        do {
            prime = new BigInteger(bitLength, random);
            if (prime.compareTo(BigInteger.TWO) < 0) {
                continue;
            }
            // 确保是奇数
            if (prime.mod(BigInteger.TWO).equals(BigInteger.ZERO)) {
                prime = prime.add(BigInteger.ONE);
            }
        } while (!isProbablePrime(prime, certainty));
        
        return prime;
    }
    
    /**
     * 生成范围内的随机BigInteger [min, max]
     */
    public static BigInteger randomBigInteger(BigInteger min, BigInteger max) {
        BigInteger range = max.subtract(min).add(BigInteger.ONE);
        int bitLength = range.bitLength();
        BigInteger result;
        
        do {
            result = new BigInteger(bitLength, random);
        } while (result.compareTo(range) >= 0);
        
        return result.add(min);
    }
    
    /**
     * 扩展欧几里得算法
     * 返回 [gcd, x, y] 使得 ax + by = gcd(a,b)
     */
    public static BigInteger[] extendedGCD(BigInteger a, BigInteger b) {
        if (b.equals(BigInteger.ZERO)) {
            return new BigInteger[]{a, BigInteger.ONE, BigInteger.ZERO};
        }
        
        BigInteger[] result = extendedGCD(b, a.mod(b));
        BigInteger gcd = result[0];
        BigInteger x = result[2];
        BigInteger y = result[1].subtract(a.divide(b).multiply(result[2]));
        
        return new BigInteger[]{gcd, x, y};
    }
    
    /**
     * 模逆运算: 计算 a^(-1) mod m
     */
    public static BigInteger modInverse(BigInteger a, BigInteger m) {
        BigInteger[] result = extendedGCD(a, m);
        if (!result[0].equals(BigInteger.ONE)) {
            throw new ArithmeticException("模逆不存在");
        }
        return result[1].mod(m);
    }
    
    /**
     * 计算整数的平方根上界
     */
    public static BigInteger sqrt(BigInteger n) {
        if (n.compareTo(BigInteger.ZERO) < 0) {
            throw new ArithmeticException("负数没有平方根");
        }
        if (n.equals(BigInteger.ZERO) || n.equals(BigInteger.ONE)) {
            return n;
        }
        
        BigInteger two = BigInteger.TWO;
        BigInteger x = n.divide(two);
        BigInteger y = x.add(n.divide(x)).divide(two);
        
        while (y.compareTo(x) < 0) {
            x = y;
            y = x.add(n.divide(x)).divide(two);
        }
        
        return x;
    }
    
    /**
     * 分解素因数（简单实现，用于小数）
     */
    public static List<BigInteger> factorize(BigInteger n) {
        List<BigInteger> factors = new ArrayList<>();
        BigInteger two = BigInteger.TWO;
        
        // 处理因子2
        while (n.mod(two).equals(BigInteger.ZERO)) {
            factors.add(two);
            n = n.divide(two);
        }
        
        // 处理奇数因子
        BigInteger i = BigInteger.valueOf(3);
        BigInteger maxFactor = sqrt(n);
        
        while (i.compareTo(maxFactor) <= 0) {
            while (n.mod(i).equals(BigInteger.ZERO)) {
                factors.add(i);
                n = n.divide(i);
            }
            i = i.add(two);
        }
        
        // 如果n > 1，则n本身是素数
        if (n.compareTo(BigInteger.ONE) > 0) {
            factors.add(n);
        }
        
        return factors;
    }
    
    /**
     * 计算n的欧拉函数φ(n)
     */
    public static BigInteger eulerPhi(BigInteger n) {
        if (n.equals(BigInteger.ONE)) {
            return BigInteger.ONE;
        }
        
        BigInteger result = n;
        BigInteger temp = n;
        BigInteger two = BigInteger.TWO;
        
        // 处理因子2
        if (temp.mod(two).equals(BigInteger.ZERO)) {
            result = result.divide(two);
            while (temp.mod(two).equals(BigInteger.ZERO)) {
                temp = temp.divide(two);
            }
        }
        
        // 处理奇数因子
        BigInteger i = BigInteger.valueOf(3);
        BigInteger maxFactor = sqrt(temp);
        
        while (i.compareTo(maxFactor) <= 0) {
            if (temp.mod(i).equals(BigInteger.ZERO)) {
                result = result.subtract(result.divide(i));
                while (temp.mod(i).equals(BigInteger.ZERO)) {
                    temp = temp.divide(i);
                }
            }
            i = i.add(two);
        }
        
        if (temp.compareTo(BigInteger.ONE) > 0) {
            result = result.subtract(result.divide(temp));
        }
        
        return result;
    }
    
    /**
     * 生成安全素数 p = 2q + 1，其中q也是素数
     * 这种素数对Pollard's Rho算法更友好
     * @param bitLength 目标位数
     * @return 安全素数
     */
    public static BigInteger generateSafePrime(int bitLength) {
        int attempts = 0;
        int maxAttempts = 1000;
        
        while (attempts < maxAttempts) {
            // 生成q
            BigInteger q = generatePrime(bitLength - 1, 10);
            // 计算 p = 2q + 1
            BigInteger p = q.multiply(BigInteger.TWO).add(BigInteger.ONE);
            
            // 检查p是否也是素数
            if (isProbablePrime(p, 10)) {
                return p;
            }
            attempts++;
        }
        
        // 如果无法生成安全素数，降级为普通素数
        return generatePrime(bitLength, 10);
    }
}

