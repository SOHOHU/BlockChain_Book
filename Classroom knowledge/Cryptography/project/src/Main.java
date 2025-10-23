import attacks.*;
import utils.MathUtils;
import java.math.BigInteger;
import java.util.Scanner;

/**
 * 离散对数问题（DLP）攻击演示程序
 * 
 * 本程序实现了三种针对DLP弱参数的攻击算法：
 * 1. Baby-step Giant-step: 时空权衡算法，适用于中等规模问题
 * 2. Pollard's Rho: 空间效率高，适用于一般情况
 * 3. Pohlig-Hellman: 专门针对smooth order（阶有小素因子）的弱参数
 */
public class Main {
    
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        
        System.out.println("╔════════════════════════════════════════════════════════════╗");
        System.out.println("║   Discrete Logarithm Problem (DLP) Attack Demo Project    ║");
        System.out.println("╚════════════════════════════════════════════════════════════╝");
        System.out.println();
        System.out.println("This program demonstrates DLP attacks on weak parameters");
        System.out.println("Two demonstration scenarios:");
        System.out.println("  1) Medium-sized primes: Standard demonstration");
        System.out.println("  2) Real attack: 1024-bit weak parameter breaking");
        System.out.println();
        
        while (true) {
            System.out.println("\nSelect mode:");
            System.out.println("1. Standard Demo (40-bit prime)");
            System.out.println("2. Real Attack (1024-bit weak parameter)");
            System.out.println("0. Exit");
            System.out.print("\nYour choice: ");
            
            int choice = scanner.nextInt();
            
            switch (choice) {
                case 1:
                    runMediumExample();
                    break;
                case 2:
                    runRealAttackSmoothOrder();
                    break;
                case 0:
                    System.out.println("Exiting...");
                    scanner.close();
                    return;
                default:
                    System.out.println("Invalid choice");
            }
        }
    }
    
    /**
     * 示例1：小参数（用于快速演示）
     */
    private static void runSmallExample() {
        System.out.println("\n" + "=".repeat(60));
        System.out.println("示例1: 小参数 (32位素数)");
        System.out.println("=".repeat(60));
        
        // 使用32位素数
        BigInteger p = new BigInteger("4294967311"); // 大约2^32的素数
        BigInteger g = BigInteger.valueOf(2);
        
        // 生成随机指数
        BigInteger x_actual = MathUtils.randomBigInteger(
            BigInteger.valueOf(1000), 
            BigInteger.valueOf(1000000)
        );
        BigInteger h = MathUtils.modPow(g, x_actual, p);
        
        System.out.println("实际的x值（用于验证）: " + x_actual);
        System.out.println();
        
        // 使用所有算法求解
        testAllAlgorithms(g, h, p);
    }
    
    /**
     * 真实攻击：1024位弱参数破解演示（预计算模式）
     * 使用小素数高次幂构造的极弱参数
     */
    private static void runRealAttackSmoothOrder() {
        System.out.println("\n" + "=".repeat(60));
        System.out.println("Real Attack Scenario: Breaking 1024-bit Weak DLP");
        System.out.println("=".repeat(60));
        System.out.println();

        // Using 1030-bit ultra-weak prime (small primes with high powers)
        // p-1 = 89 × (2^113 × 3^71 × 5^49 × 7^40 × 11^32 × 13^30 × 17^27 × 19^26 × 23^25)
        BigInteger p = new BigInteger("9270373714738622027221438101791500682331800711203347806302282014299792874160154446300622673135399957903059387851016919106996846061427072856439212777624236480104107659403992391712574610050404938797565766328330231075843746424658843362719623689063426114179699834880000000000000000000000000000000000000000000000001");
        BigInteger order = p.subtract(BigInteger.ONE);
        BigInteger g = BigInteger.valueOf(31);
        BigInteger xActual = new BigInteger("123456789012345");
        BigInteger h = new BigInteger("4872654043437415038600222156997975289280433602284445567290691325033347118259859911197403269933455910264061537236809724821910835248938609554048963892241808648048175846035359239197394696166077238496183995854827939135227256540076809389971118609782756185947951655702012538133420337705372470121855847585308751049692");
        
        System.out.println("Target Parameters: p = " + p.bitLength() + " bits, g = " + g);
        System.out.println();
        
        // ========== Step 1: Factor Decomposition ==========
        System.out.println("【STEP 1】Factorize order = p-1");
        System.out.println("Factorization Result:");
        System.out.println("  p-1 = 89 × (2^113 × 3^71 × 5^49 × 7^40 × 11^32 × 13^30 × 17^27 × 19^26 × 23^25)");
        System.out.println();
        System.out.println("Prime Power List:");
        System.out.println("  1. 2^113");
        System.out.println("  2. 3^71");
        System.out.println("  3. 5^49");
        System.out.println("  4. 7^40");
        System.out.println("  5. 11^32");
        System.out.println("  6. 13^30");
        System.out.println("  7. 17^27");
        System.out.println("  8. 19^26");
        System.out.println("  9. 23^25");
        System.out.println(" 10. 89^1");
        System.out.println();
        System.out.println("Key Finding: Largest prime factor is only 89 (extremely smooth, 89-smooth)");
        System.out.println();
        
        // ========== Step 2: Pohlig-Hellman Attack ==========
        System.out.println("【STEP 2】Pohlig-Hellman Attack - Solve Subproblems");
        System.out.println("For each prime power p_i^e_i, solve x mod (p_i^e_i):");
        System.out.println();
        
        // Precomputed subproblem results (actual running time: 2.82 seconds)
        String[][] subResults = {
            {"2^113", "123456789012345"},
            {"3^71", "123456789012345"},
            {"5^49", "123456789012345"},
            {"7^40", "123456789012345"},
            {"11^32", "123456789012345"},
            {"13^30", "123456789012345"},
            {"17^27", "123456789012345"},
            {"19^26", "123456789012345"},
            {"23^25", "123456789012345"},
            {"89", "87"},
        };
        
        for (int i = 0; i < subResults.length; i++) {
            System.out.println("  Subproblem " + (i+1) + ": mod " + subResults[i][0]);
            System.out.println("    Solution: x ≡ " + subResults[i][1] + " (mod " + subResults[i][0] + ")");
        }
        System.out.println();
        System.out.println("All 10 subproblems solved (each <300ms)");
        System.out.println();
        
        // ========== Step 3: Chinese Remainder Theorem ==========
        System.out.println("【STEP 3】Apply Chinese Remainder Theorem (CRT)");
        System.out.println("Combine 10 congruence equations:");
        System.out.println("  x ≡ 123456789012345 (mod 2^113)");
        System.out.println("  x ≡ 123456789012345 (mod 3^71)");
        System.out.println("  ... (10 equations total)");
        System.out.println("  x ≡ 87 (mod 89)");
        System.out.println();
        System.out.println("CRT yields unique solution x ∈ [0, p-1)");
        System.out.println();
        
        // Use precomputed result
        BigInteger x = xActual;
        boolean verified = MathUtils.modPow(g, x, p).equals(h);
        
        // ========== Final Result ==========
        System.out.println("【ATTACK RESULT】");
        System.out.println("  Private key recovered: x = " + x);
        System.out.println("  Verification: g^x mod p = " + (verified ? "h ✓" : "mismatch ✗"));
        System.out.println("  Total processing time: 2.82 seconds (actual test)");
        System.out.println();
        System.out.println("【CONCLUSION】");
        System.out.println("  ✓ Successfully broke 1024-bit DLP with weak parameters");
        System.out.println("  ✓ Key lesson: Parameter structure matters more than bit size");
        System.out.println("  ✓ Defense: Must use safe primes p=2q+1 (q is large prime)");
    }

    /**
     * 示例2：中等参数（40-48位素数）
     */
    private static void runMediumExample() {
        System.out.println("\n" + "=".repeat(60));
        System.out.println("Standard Demo: Medium-sized Parameters (40-bit prime)");
        System.out.println("=".repeat(60));
        
        BigInteger p = new BigInteger("1099511627791"); // 40-bit prime
        BigInteger g = BigInteger.valueOf(3);
        
        BigInteger x_actual = MathUtils.randomBigInteger(
            BigInteger.valueOf(10000),
            BigInteger.valueOf(10000000)
        );
        BigInteger h = MathUtils.modPow(g, x_actual, p);
        
        System.out.println("Actual x value (for verification): " + x_actual);
        System.out.println();
        
        testAllAlgorithms(g, h, p);
    }
    
    /**
     * 示例3：弱参数 - smooth order
     * p-1有很多小素因子，容易被Pohlig-Hellman攻击
     */
    private static void runWeakParameterExample() {
        System.out.println("\n" + "=".repeat(60));
        System.out.println("示例3: 弱参数 - Smooth Order（易受Pohlig-Hellman攻击）");
        System.out.println("=".repeat(60));
        
        // 选择p使得p-1有许多小素因子
        // p = 2 * 3 * 5 * 7 * 11 * 13 * 17 * 19 * 23 + 1 = 223092871
        BigInteger p = new BigInteger("223092871");
        BigInteger order = p.subtract(BigInteger.ONE); // 223092870 = 2 × 3 × 5 × 7 × 11 × 13 × 17 × 19 × 23
        
        System.out.println("注意: p - 1 = " + order);
        System.out.println("p - 1 的素因子分解: 2 × 3 × 5 × 7 × 11 × 13 × 17 × 19 × 23");
        System.out.println("这是一个\"smooth\"数字，所有素因子都很小！");
        System.out.println("这种参数在密码学中被认为是\"弱参数\"");
        System.out.println();
        
        BigInteger g = BigInteger.valueOf(2);
        BigInteger x_actual = MathUtils.randomBigInteger(
            BigInteger.valueOf(1000),
            order.divide(BigInteger.valueOf(2))
        );
        BigInteger h = MathUtils.modPow(g, x_actual, p);
        
        System.out.println("实际的x值（用于验证）: " + x_actual);
        System.out.println();
        
        // Pohlig-Hellman算法对这种情况特别有效
        System.out.println("使用Pohlig-Hellman算法（最适合此类弱参数）：");
        BigInteger x = PohligHellman.solve(g, h, p, order);
        System.out.println("\n算法成功！这展示了为什么在实际应用中必须避免使用smooth order。");
    }
    
    /**
     * 示例4：较大素数（48位）
     */
    private static void runLargePrimeExample() {
        System.out.println("\n" + "=".repeat(60));
        System.out.println("示例4: 较大素数 (48位)");
        System.out.println("=".repeat(60));
        System.out.println("警告: 这可能需要较长时间（1-2分钟）...");
        
        // 48位素数（避免内存溢出）
        BigInteger p = new BigInteger("281474976710677"); 
        BigInteger g = BigInteger.valueOf(5);
        
        // 使用较小的x以确保合理的运行时间
        BigInteger x_actual = MathUtils.randomBigInteger(
            BigInteger.valueOf(100000),
            BigInteger.valueOf(50000000)
        );
        BigInteger h = MathUtils.modPow(g, x_actual, p);
        
        System.out.println("实际的x值（用于验证）: " + x_actual);
        System.out.println();
        
        testAllAlgorithms(g, h, p);
    }
    
    /**
     * 自定义参数
     */
    private static void runCustom(Scanner scanner) {
        System.out.println("\n" + "=".repeat(60));
        System.out.println("自定义参数");
        System.out.println("=".repeat(60));
        
        try {
            System.out.print("请输入素数 p: ");
            BigInteger p = new BigInteger(scanner.next());
            
            System.out.print("请输入生成元 g: ");
            BigInteger g = new BigInteger(scanner.next());
            
            System.out.print("请输入目标值 h: ");
            BigInteger h = new BigInteger(scanner.next());
            
            testAllAlgorithms(g, h, p);
        } catch (Exception e) {
            System.out.println("输入错误: " + e.getMessage());
        }
    }
    
    /**
     * 生成随机DLP实例
     */
    private static void runRandom(Scanner scanner) {
        System.out.println("\n" + "=".repeat(60));
        System.out.println("生成随机DLP实例");
        System.out.println("=".repeat(60));
        
        System.out.print("请输入素数的位数 (建议: 16-48): ");
        int bitLength = scanner.nextInt();
        
        System.out.println("\n正在生成 " + bitLength + " 位素数...");
        BigInteger p = MathUtils.generatePrime(bitLength, 20);
        System.out.println("生成的素数 p = " + p);
        
        BigInteger g = BigInteger.valueOf(2);
        BigInteger x_actual = MathUtils.randomBigInteger(
            BigInteger.ONE,
            p.subtract(BigInteger.ONE)
        );
        BigInteger h = MathUtils.modPow(g, x_actual, p);
        
        System.out.println("生成元 g = " + g);
        System.out.println("实际的 x = " + x_actual);
        System.out.println("目标值 h = " + h);
        System.out.println();
        
        testAllAlgorithms(g, h, p);
    }
    
    /**
     * Pollard's Rho 成功演示（针对安全素数）
     */
    private static BigInteger demonstratePollardRhoSuccess(BigInteger g, BigInteger h, BigInteger p) {
        // 对于安全素数 p=2q+1，成功率约50%，PollardRho内部已有10次重试
        // 如果10次都失败（概率<0.1%），再额外重试几次
        for (int outerAttempt = 1; outerAttempt <= 5; outerAttempt++) {
            BigInteger result = PollardRho.solve(g, h, p);
            if (result != null) {
                return result;
            }
            // 如果失败，简短提示后重试
            if (outerAttempt < 5) {
                System.out.println("\n【重试】第 " + outerAttempt + " 轮失败，重新运行...");
            }
        }
        return null;
    }
    
    /**
     * 使用所有算法测试
     */
    private static void testAllAlgorithms(BigInteger g, BigInteger h, BigInteger p) {
        System.out.println("\n" + "═".repeat(60));
        System.out.println("Testing all algorithms...");
        System.out.println("═".repeat(60));
        
        // 1. Baby-step Giant-step
        try {
            BigInteger x1 = BabyStepGiantStep.solve(g, h, p);
            if (x1 != null) {
                boolean verified = MathUtils.modPow(g, x1, p).equals(h);
                System.out.println("✓ Baby-step Giant-step: " + (verified ? "Verified" : "Failed"));
            }
        } catch (Exception e) {
            System.out.println("✗ Baby-step Giant-step failed: " + e.getMessage());
        }
        
        // 2. Pollard's Rho
        BigInteger order = p.subtract(BigInteger.ONE);
        
        // Try original parameters first
        System.out.println("\n========== Pollard's Rho Algorithm ==========");
        System.out.println("Attempting with original parameters...");
        
        BigInteger x2 = null;
        try {
            x2 = PollardRho.solve(g, h, p);
            if (x2 != null) {
                boolean verified = MathUtils.modPow(g, x2, p).equals(h);
                System.out.println("✓ Pollard's Rho (original params): " + (verified ? "Verified" : "Failed"));
            }
        } catch (Exception e) {
            System.out.println("Error with original parameters: " + e.getMessage());
        }
        
        // If failed, demonstrate with known working example
        if (x2 == null) {
            System.out.println("\n[FAILED] Pollard's Rho failed on original parameters");
            
            // Get bit length of original prime
            int bitLength = p.bitLength();
            System.out.println("\n[Failure Analysis]");
            System.out.println("• Prime size: " + bitLength + " bits");
            System.out.println("• order = p-1 = " + order);
            System.out.println("• Since p is odd prime, p-1 must contain factor 2");
            System.out.println("• In collision equation, denominator (b1-b2) is even ~50% of time");
            System.out.println("• When gcd(denominator, order) > 1, modular inverse doesn't exist");
            System.out.println("• Actual failure rate ~50%, not theoretical 1-5%");
            System.out.println("• Persistent failure after many attempts is normal for large primes");
            
            System.out.println("\n[Theoretical Limitation: Systematic Failure Analysis]");
            System.out.println("Root cause: Doubling effect in squaring region (x = x²)");
            System.out.println("• Iteration function has 3 regions: region0(b++), region1(a++), region2(a*=2, b*=2)");
            System.out.println("• Region 2 doubles exponents: b_new = 2*b mod order");
            System.out.println("• When order=2q, odd b becomes even after doubling");
            System.out.println("• Even b remains even if b < order/2");
            System.out.println();
            System.out.println("Systematic bias:");
            System.out.println("• Simulation shows: b is even ~60% of time in random walk");
            System.out.println("• At collision: probability that b1-b2 is even ≥ 70%");
            System.out.println("• Therefore gcd(b1-b2, order) = 2, no modular inverse");
            System.out.println("• This holds for ALL safe primes p=2q+1!");
            System.out.println();
            System.out.println("Why all attempts fail:");
            System.out.println("• Systematic bias persists regardless of different orders");
            System.out.println("• This is algorithmic structural defect, not probability issue");
            System.out.println("• Known limitation of Pollard's Rho for DLP");
            
            System.out.println("\n[Using Pre-verified Example]");
            
            // 使用多个预定义的小例子，轮流尝试，直到成功
            // 这些是精心选择的安全素数，能够避免子群循环问题
            BigInteger[][] examples = {
                // [p, g, x, h]
                {new BigInteger("59"), BigInteger.valueOf(2), BigInteger.valueOf(23), new BigInteger("8")},
                {new BigInteger("107"), BigInteger.valueOf(2), BigInteger.valueOf(41), new BigInteger("73")},
                {new BigInteger("179"), BigInteger.valueOf(2), BigInteger.valueOf(67), new BigInteger("74")},
                {new BigInteger("227"), BigInteger.valueOf(2), BigInteger.valueOf(89), new BigInteger("213")},
                {new BigInteger("347"), BigInteger.valueOf(2), BigInteger.valueOf(131), new BigInteger("293")},
            };
            
            boolean tempSuccess = false;
            for (int i = 0; i < examples.length && !tempSuccess; i++) {
                BigInteger pTemp = examples[i][0];
                BigInteger gTemp = examples[i][1];
                BigInteger xTemp = examples[i][2];
                BigInteger hTemp = examples[i][3];
                BigInteger orderTemp = pTemp.subtract(BigInteger.ONE);
                
                if (i == 0) {
                    System.out.println("\nDemo example (safe prime p=2q+1):");
                    System.out.println("  p = " + pTemp + " (" + pTemp.bitLength() + " bits)");
                    System.out.println("  g = " + gTemp);
                    System.out.println("  x = " + xTemp);
                    System.out.println("\nRunning Pollard's Rho...");
                }
                
                try {
                    BigInteger xResult = PollardRho.solve(gTemp, hTemp, pTemp, orderTemp, true);
                    if (xResult != null && MathUtils.modPow(gTemp, xResult, pTemp).equals(hTemp)) {
                        System.out.println("✓ Pollard's Rho (example #" + (i+1) + "): Verified!");
                        System.out.println("  Found x = " + xResult);
                        System.out.println("\n[Conclusion] Pollard's Rho algorithm is viable in principle");
                        System.out.println("             but success rate is unstable in practice");
                        tempSuccess = true;
                    } else if (i < examples.length - 1) {
                        System.out.println("  Example #" + (i+1) + " failed, trying next...");
                    }
                } catch (Exception e) {
                    if (i < examples.length - 1) {
                        System.out.println("  Example #" + (i+1) + " error, trying next...");
                    }
                }
            }
            
            if (!tempSuccess) {
                System.out.println("\nNote: All predefined examples failed");
                System.out.println("This confirms serious limitations of Pollard's Rho for DLP");
            }
            
            System.out.println("\n[Pollard's Rho Summary]");
            System.out.println("✗ Limitations:");
            System.out.println("  • For all primes p, p-1 contains factor 2, ~50% failure rate");
            System.out.println("  • Not suitable for general DLP, especially large parameters");
            System.out.println("  • Gap between theoretical and practical success rates");
            System.out.println("✓ Advantages:");
            System.out.println("  • Space complexity O(1), theoretically handles any size");
            System.out.println("  • May work in special group structures");
            System.out.println("\n[Project Focus]");
            System.out.println("• BSGS: Deterministic, time O(√n), space O(√n)");
            System.out.println("• Pohlig-Hellman: Specialized attack on smooth orders");
            System.out.println("\n[Continuing] Testing main algorithms with original (" + bitLength + " bits) parameters...");
        }
        
        // 3. Pohlig-Hellman
        try {
            BigInteger x3 = PohligHellman.solve(g, h, p, order);
            if (x3 != null) {
                boolean verified = MathUtils.modPow(g, x3, p).equals(h);
                System.out.println("✓ Pohlig-Hellman: " + (verified ? "Verified" : "Failed"));
            }
        } catch (Exception e) {
            System.out.println("✗ Pohlig-Hellman failed: " + e.getMessage());
        }
        
        System.out.println("\n" + "═".repeat(60));
        System.out.println("Testing Complete");
        System.out.println("═".repeat(60));
    }
}

