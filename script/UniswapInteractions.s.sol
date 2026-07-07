// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ERC20Token} from "../src/ERC20Token.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// --- Uniswap V2 Interfaces ---

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IUniswapV2Factory {
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Pair {
    function balanceOf(address owner) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
}

// --- Uniswap V3 Interfaces ---

interface IUniswapV3Factory {
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);
}

interface IUniswapV3Pool {
    function initialize(uint160 sqrtPriceX96) external;
}

interface ISwapRouter02 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);
}

interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }
    function mint(
        MintParams calldata params
    )
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }
    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }
    function collect(
        CollectParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
}

// --- Interactions Script ---

contract UniswapInteractions is Script {
    // Canonical Robinhood Chain Mainnet Addresses
    address public constant V2_FACTORY =
        0x8bcEaA40B9AcdfAedF85AdF4FF01F5Ad6517937f;
    address public constant V2_ROUTER =
        0x89e5DB8B5aA49aA85AC63f691524311AEB649eba;
    address public constant V3_FACTORY =
        0x1f7d7550B1b028f7571E69A784071F0205FD2EfA;
    address public constant V3_ROUTER =
        0xCaf681a66D020601342297493863E78C959E5cb2;
    address public constant V3_POSITION_MANAGER =
        address(uint160(0x0073991a25c818bf1f1128deaab1492d45638de0d3));
    // Canonical Robinhood Chain Stock/Stable Tokens
    address public constant MAINNET_USDG =
        0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168;
    address public constant MAINNET_AAPL =
        0xaF3D76f1834A1d425780943C99Ea8A608f8a93f9;
    address public constant MAINNET_TSLA =
        0x322F0929c4625eD5bAd873c95208D54E1c003b2d;
    address public constant MAINNET_WETH =
        0x0Bd7D308f8E1639FAb988df18A8011f41EAcAD73;

    function run() external {
        vm.startBroadcast();

        // 1. Read Interaction parameters
        string memory action = vm.envOr("ACTION", string("v2_add_lp"));
        uint256 amountA = vm.envOr("AMOUNT_A", uint256(100 ether));
        uint256 amountB = vm.envOr("AMOUNT_B", uint256(1 ether));
        uint24 feeTier = uint24(vm.envOr("V3_FEE", uint256(3000))); // default 0.3%

        // 2. Detect Network & Determine Token Addresses
        address tokenA;
        address tokenB;

        // Fetch custom token overrides or default to canonical stock tokens
        address envTokenA = vm.envOr("TOKEN_A", address(0));
        address envTokenB = vm.envOr("TOKEN_B", address(0));

        // Detect if we are running on a network with actual canonical tokens (Robinhood Chain ID: 4663)
        bool isRobinhoodMainnet = (block.chainid == 4663);

        if (envTokenA != address(0) && envTokenB != address(0)) {
            tokenA = envTokenA;
            tokenB = envTokenB;
            console.log(
                "Using custom tokens provided via environment variables:"
            );
        } else if (isRobinhoodMainnet) {
            // Check if caller has sufficient balance of canonical mainnet tokens
            bool hasBalance = false;
            try IERC20(MAINNET_USDG).balanceOf(msg.sender) returns (
                uint256 balA
            ) {
                try IERC20(MAINNET_AAPL).balanceOf(msg.sender) returns (
                    uint256 balB
                ) {
                    if (balA >= amountA && balB >= amountB) {
                        hasBalance = true;
                    }
                } catch {}
            } catch {}
            if (hasBalance) {
                tokenA = MAINNET_USDG;
                tokenB = MAINNET_AAPL;
                console.log(
                    "On Robinhood Mainnet/Fork with sufficient balance. Using canonical stock tokens:"
                );
            } else {
                console.log(
                    "On Robinhood Mainnet/Fork but caller lacks token balance. Deploying Mock USDG and Mock AAPL tokens..."
                );
                ERC20Token mockUSDG = new ERC20Token(
                    "Mock USDG",
                    "USDG",
                    1_000_000,
                    msg.sender
                );
                ERC20Token mockAAPL = new ERC20Token(
                    "Mock AAPL",
                    "AAPL",
                    1_000_000,
                    msg.sender
                );
                tokenA = address(mockUSDG);
                tokenB = address(mockAAPL);
                console.log("Mock tokens deployed:");
            }
        } else {
            console.log(
                "Not on Robinhood Mainnet. Deploying Mock USDG and Mock AAPL tokens..."
            );
            ERC20Token mockUSDG = new ERC20Token(
                "Mock USDG",
                "USDG",
                1_000_000,
                msg.sender
            );
            ERC20Token mockAAPL = new ERC20Token(
                "Mock AAPL",
                "AAPL",
                1_000_000,
                msg.sender
            );
            tokenA = address(mockUSDG);
            tokenB = address(mockAAPL);
            console.log("Mock tokens deployed:");
        }

        console.log("- Token A (USDG/Stable):", tokenA);
        console.log("- Token B (AAPL/Stock):", tokenB);

        // Sort tokens for Uniswap V3 compatibility
        address token0 = tokenA < tokenB ? tokenA : tokenB;
        address token1 = tokenA < tokenB ? tokenB : tokenA;

        console.log("Executing action:", action);

        if (keccak256(bytes(action)) == keccak256(bytes("v2_add_lp"))) {
            executeV2AddLiquidity(tokenA, tokenB, amountA, amountB);
        } else if (
            keccak256(bytes(action)) == keccak256(bytes("v2_remove_lp"))
        ) {
            uint256 lpAmount = vm.envOr("LIQUIDITY", uint256(0));
            executeV2RemoveLiquidity(tokenA, tokenB, lpAmount);
        } else if (keccak256(bytes(action)) == keccak256(bytes("v2_swap"))) {
            executeV2Swap(tokenA, tokenB, amountA);
        } else if (keccak256(bytes(action)) == keccak256(bytes("v3_add_lp"))) {
            int24 tickLower = int24(vm.envOr("V3_TICK_LOWER", int256(-887220))); // min tick
            int24 tickUpper = int24(vm.envOr("V3_TICK_UPPER", int256(887220))); // max tick
            executeV3AddLiquidity(
                token0,
                token1,
                feeTier,
                amountA,
                amountB,
                tickLower,
                tickUpper
            );
        } else if (
            keccak256(bytes(action)) == keccak256(bytes("v3_remove_lp"))
        ) {
            uint256 tokenId = vm.envOr("TOKEN_ID", uint256(0));
            uint128 liquidity = uint128(vm.envOr("LIQUIDITY", uint256(0)));
            executeV3RemoveLiquidity(tokenId, liquidity);
        } else if (keccak256(bytes(action)) == keccak256(bytes("v3_swap"))) {
            executeV3Swap(tokenA, tokenB, feeTier, amountA);
        } else {
            console.log(
                "Unknown action. Available: v2_add_lp, v2_remove_lp, v2_swap, v3_add_lp, v3_remove_lp, v3_swap"
            );
        }

        vm.stopBroadcast();
    }

    // --- Action Implementations ---

    function executeV2AddLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB
    ) internal {
        console.log("Approving tokens for Uniswap V2 Router...");
        IERC20(tokenA).approve(V2_ROUTER, amountA);
        IERC20(tokenB).approve(V2_ROUTER, amountB);

        // Ensure pair exists or create it
        address pair = IUniswapV2Factory(V2_FACTORY).getPair(tokenA, tokenB);
        if (pair == address(0)) {
            console.log("Creating new V2 pair...");
            pair = IUniswapV2Factory(V2_FACTORY).createPair(tokenA, tokenB);
            console.log("V2 Pair created at:", pair);
        } else {
            console.log("V2 Pair already exists at:", pair);
        }

        console.log("Adding liquidity to V2 Router...");
        (
            uint256 amountSentA,
            uint256 amountSentB,
            uint256 lpReceived
        ) = IUniswapV2Router02(V2_ROUTER).addLiquidity(
                tokenA,
                tokenB,
                amountA,
                amountB,
                0, // min amount A
                0, // min amount B
                msg.sender,
                block.timestamp + 600
            );

        console.log("V2 Liquidity successfully added!");
        console.log("- Token A supplied:", amountSentA);
        console.log("- Token B supplied:", amountSentB);
        console.log("- LP Tokens received:", lpReceived);
    }

    function executeV2RemoveLiquidity(
        address tokenA,
        address tokenB,
        uint256 lpAmount
    ) internal {
        address pair = IUniswapV2Factory(V2_FACTORY).getPair(tokenA, tokenB);
        require(
            pair != address(0),
            "Uniswap V2 pair does not exist for these tokens"
        );

        if (lpAmount == 0) {
            lpAmount = IERC20(pair).balanceOf(msg.sender);
            console.log(
                "LIQUIDITY param was 0. Removing full LP balance:",
                lpAmount
            );
        }
        require(lpAmount > 0, "No LP tokens to remove");

        console.log("Approving LP tokens for V2 Router...");
        IERC20(pair).approve(V2_ROUTER, lpAmount);

        console.log("Removing liquidity from V2...");
        (uint256 amountReceivedA, uint256 amountReceivedB) = IUniswapV2Router02(
            V2_ROUTER
        ).removeLiquidity(
                tokenA,
                tokenB,
                lpAmount,
                0, // min token A out
                0, // min token B out
                msg.sender,
                block.timestamp + 600
            );

        console.log("V2 Liquidity successfully removed!");
        console.log("- Token A returned:", amountReceivedA);
        console.log("- Token B returned:", amountReceivedB);
    }

    function executeV2Swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal {
        console.log("Approving input token for V2 Router...");
        IERC20(tokenIn).approve(V2_ROUTER, amountIn);

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        console.log("Swapping on Uniswap V2...");
        uint256[] memory amounts = IUniswapV2Router02(V2_ROUTER)
            .swapExactTokensForTokens(
                amountIn,
                0, // min amount out
                path,
                msg.sender,
                block.timestamp + 600
            );

        console.log("V2 Swap successful!");
        console.log("- Tokens In:", amounts[0]);
        console.log("- Tokens Out:", amounts[1]);
    }

    function executeV3AddLiquidity(
        address token0,
        address token1,
        uint24 feeTier,
        uint256 amount0Desired,
        uint256 amount1Desired,
        int24 tickLower,
        int24 tickUpper
    ) internal {
        console.log("Approving tokens for Uniswap V3 Position Manager...");
        IERC20(token0).approve(V3_POSITION_MANAGER, amount0Desired);
        IERC20(token1).approve(V3_POSITION_MANAGER, amount1Desired);

        // Check if pool exists, create and initialize if it doesn't
        address pool = IUniswapV3Factory(V3_FACTORY).getPool(
            token0,
            token1,
            feeTier
        );
        if (pool == address(0)) {
            console.log("Creating new V3 pool...");
            pool = IUniswapV3Factory(V3_FACTORY).createPool(
                token0,
                token1,
                feeTier
            );
            console.log("V3 Pool created at:", pool);

            // Initialize at 1:1 price (79228162514264337593543950336 is 1 in Q64.96)
            uint160 initSqrtPriceX96 = 79228162514264337593543950336;
            IUniswapV3Pool(pool).initialize(initSqrtPriceX96);
            console.log("V3 Pool initialized with starting price 1:1");
        } else {
            console.log("V3 Pool already exists at:", pool);
        }

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: feeTier,
                tickLower: tickLower,
                tickUpper: tickUpper,
                amount0Desired: amount0Desired,
                amount1Desired: amount1Desired,
                amount0Min: 0,
                amount1Min: 0,
                recipient: msg.sender,
                deadline: block.timestamp + 600
            });

        console.log("Minting V3 LP Position...");
        (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        ) = INonfungiblePositionManager(V3_POSITION_MANAGER).mint(params);

        console.log("V3 LP Position successfully minted!");
        console.log("- Token ID:", tokenId);
        console.log("- Liquidity value:", uint256(liquidity));
        console.log("- Token 0 supplied:", amount0);
        console.log("- Token 1 supplied:", amount1);
    }

    function executeV3RemoveLiquidity(
        uint256 tokenId,
        uint128 liquidity
    ) internal {
        require(tokenId > 0, "Must specify a valid TOKEN_ID");

        if (liquidity == 0) {
            // Read liquidity from the Position Manager
            (, , , , , , , liquidity, , , , ) = INonfungiblePositionManager(
                V3_POSITION_MANAGER
            ).positions(tokenId);
            console.log(
                "LIQUIDITY param was 0. Decreasing full position liquidity:",
                uint256(liquidity)
            );
        }
        require(liquidity > 0, "Position has no liquidity to decrease");

        console.log("Decreasing V3 liquidity...");
        INonfungiblePositionManager.DecreaseLiquidityParams
            memory decreaseParams = INonfungiblePositionManager
                .DecreaseLiquidityParams({
                    tokenId: tokenId,
                    liquidity: liquidity,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp + 600
                });

        (
            uint256 amount0Decreased,
            uint256 amount1Decreased
        ) = INonfungiblePositionManager(V3_POSITION_MANAGER).decreaseLiquidity(
                decreaseParams
            );

        console.log(
            "V3 Liquidity decreased. Now collecting accumulated tokens..."
        );

        // Collect the maximum amount of tokens
        INonfungiblePositionManager.CollectParams
            memory collectParams = INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: msg.sender,
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

        (uint256 collected0, uint256 collected1) = INonfungiblePositionManager(
            V3_POSITION_MANAGER
        ).collect(collectParams);

        console.log("V3 LP Liquidity successfully removed!");
        console.log("- Decreased Token 0 amount:", amount0Decreased);
        console.log("- Decreased Token 1 amount:", amount1Decreased);
        console.log("- Collected Token 0 amount:", collected0);
        console.log("- Collected Token 1 amount:", collected1);
    }

    function executeV3Swap(
        address tokenIn,
        address tokenOut,
        uint24 feeTier,
        uint256 amountIn
    ) internal {
        console.log("Approving input token for V3 Router...");
        IERC20(tokenIn).approve(V3_ROUTER, amountIn);

        ISwapRouter02.ExactInputSingleParams memory params = ISwapRouter02
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: feeTier,
                recipient: msg.sender,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        console.log("Executing V3 swap...");
        uint256 amountOut = ISwapRouter02(V3_ROUTER).exactInputSingle(params);

        console.log("V3 Swap successful!");
        console.log("- Token In supplied:", amountIn);
        console.log("- Token Out received:", amountOut);
    }
}
