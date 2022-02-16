// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.8.0;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point memory) {
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) pure internal returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }


    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[1];
            input[i * 6 + 3] = p2[i].X[0];
            input[i * 6 + 4] = p2[i].Y[1];
            input[i * 6 + 5] = p2[i].Y[0];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(uint256(0x2e25edd57238d74ba46aa9f92d0e607a122853584e8e999c0376892a5a704320), uint256(0x14589acb03147d208a83e51a050c033c887dbcc7d540b5b9e1d222605fab786c));
        vk.beta = Pairing.G2Point([uint256(0x1d3c3e175a5823dd488e3535d63a78876fc00b703adae5d83c9b032615949526), uint256(0x2f78dadd4f6b637f789132c1488c1d08aef3ccb2fff4f6d07c95d8b291afc2fa)], [uint256(0x1cea6d8a23b1dbe7824677c64869014ea06ae4657f2bbe0732f70aeb626fb350), uint256(0x0775be4783a8f4764a0742284d4aad20ca8c4e5070324d4f9fabe52ba3d4ecf2)]);
        vk.gamma = Pairing.G2Point([uint256(0x2ea5ec911c64f3f9bc024cf60b2baf8b943b89f4198dcd71915074b65309d728), uint256(0x2f5e49855fbf7a46b6e11550627aa4261c938c7e1b9db27de7d9dc3f020b5373)], [uint256(0x146bd3b07535cdb056690fda59e4da014b993b508b6d1207401d5477bb29f6ff), uint256(0x0aca0f96962df9d5d8e086c946f60d1224c3af729953e2d5ac5f5828c7609878)]);
        vk.delta = Pairing.G2Point([uint256(0x2f0ee1729051cb9c829ac28433db70c9c68a35d4a947345b3b0f48ada2d67087), uint256(0x134c926d6964ab86f0309c69fcab4c94efa4950466070ddc7f50b833b22fb2e0)], [uint256(0x0cd7f55706b918f28c4088e6723e954353357e978b9241e346d3c95ef77e1bb3), uint256(0x27679623a698e43fe0c95ffe9860162a15421fb5042f550f0c13e6f31d5e3838)]);
        vk.gamma_abc = new Pairing.G1Point[](57);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x0b1bbc112b9da2b1c5813997675f9dccc9f95a3591c5fe6eadd0960ac74ac448), uint256(0x26e83883843e6ecc3df61397562c9c2084288146ddbc0a37e13be817815df699));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x29c726375e93ae933dd1255379e40ada3869eec4cb1fffeec99e44e2c653b476), uint256(0x201da7300b2e366e9efe180c555ab94d74326ddc0800b3469e64e7c195077b37));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x16fab5921fb20104e4af60a6f790f97b1c8c388dd27afc54f0e9b042699934fc), uint256(0x15f71f45b61d51d553437b9ff57e6a62d5b428eb4eb1868cdbcb4b8f72f1cf79));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x12e303e4f48b80e5d10f7568e7f8d2cb7d58c437da4b452839cb6cae6edfa80c), uint256(0x1ae787ea8662e8d22ca2bd507c16117d95a7c609bce263e66cdc06457cf99fcf));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x063621d9a645a778812b5c70e8097c7e43c49c43bdbe9a8e48af2a42199fcefc), uint256(0x3016b5e5b3ef39c5368978c05c4dde44a6521348ed4d9d4eb418ff2156b0db54));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x08d5da0248e81eff4441faff3d01ea3a6cab551bf0b6060c6166ba3dd97ad0d1), uint256(0x0535270f29437ee4c0de07181bbc82e8f9c2233aacf92000c34ae100df90c158));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x065057713c1ced0e8ba037c360965dcced53122194cd327a72a5e0e080d4f9d4), uint256(0x13f62e1529c2cec1fd1fb7d81ff9eaa6c75c64c95f1bdb0a1e337becfcc5fa2a));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x00126a76ef7979007989242c6fd10fa3dfa533ca5564690924d91b0208ede76b), uint256(0x203678382c51e0a22d6009d755e4da2d396a3b6dd18091db05d4e74066f7cd9c));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x222b10a025a40b96876fc750b6f5823161d957141f565b888ceb150c898c8645), uint256(0x0f451355eb87a154f58f4f2df5910304aef4132e6a483c1b7b30926dcd98eef3));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x0d9bf8923a9aaf62494d4b664aa1928808840b686fce201d0bee4d4fcc549b33), uint256(0x14fd0b94ab0a37078545f279b9b14b303b3662513c50d73e0564dfdc19651896));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x1cc2908cdddef53927e26acc48788806ade7189388289af35952221ae0a3920a), uint256(0x2c40bc7ce6dc6ba97a1b91205c3c2acad5b4d2dc1d2975f4f41f267436e94a7e));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x0a014eb82f9821ac9600117df305b5c17c13e926618195d67ea450916e032118), uint256(0x2351b4f9cd1bca52567589c9d6cd9073acc5cbc837cd829bf2f2131bfa2f733d));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x1d4e188d52b1b48e0b42eaeb5b6a9086aff0ea4719c5cd00e4004989fd5f6e84), uint256(0x28e2826aca421f63165052a1ddeca067e3841077c13bfae0e76ff8bc42566466));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x1694dca821ea267a505dd2b3891317b0a908832b939d8fb824e229e61164910f), uint256(0x0cea64188517fefeed6cee8b853e2b70efad7d024317f434f93ba4fb073bd88e));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x0fcd1d32412d176c8c55edf138a30d008cb20336675e729a8731907a3e8a3483), uint256(0x11e28e7a6983ea5623cdeeaee3d887b54eba0374c51baaa00416187ecdb477b9));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x1cab7e2cbeb82418f3c4c836e580565ad30bcfe21f4460c2fc1a716c68f88fe0), uint256(0x17dc5fd9bf34103925ac6d296798bfe30558a73ed99458f0f2f47385d2109363));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x2f15c5bc04f64aec242511788e503b0d79aed1453d58f34d1ea961c90461ed01), uint256(0x0d1d32af39d1b817835127e1620c98782fccb896306df2c8a408afc3d5b618d7));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x2b02b4154b05e5bd39dd1754b1f129a158059a5fc6e5c51d898d94738a4ddd10), uint256(0x1e8d89e2fa40a565096970a865d93298d74c6f09d6bb9147df77db4b804065b2));
        vk.gamma_abc[18] = Pairing.G1Point(uint256(0x139e889a8b0c90499f8b7e32c0498c66ee67dd75819e0466405dbf8a3e5b1a92), uint256(0x0b3cb277b6e8519fbcbfb99aa3e369d792c421890393b0e274573bfe952cb1f9));
        vk.gamma_abc[19] = Pairing.G1Point(uint256(0x01c3d0649b5106c37acac8f2d9671231de53ae8f95efea7686dcdbf4360a1eae), uint256(0x0f2b9eb4ba7e0c78e342cc3d38cb69a02e8dbc5e2957d94696be05dfaa3b07e6));
        vk.gamma_abc[20] = Pairing.G1Point(uint256(0x2367c12169b63d2b15754bd74a2de6cb1daf7665cdcb8ad9a1227e9234764af5), uint256(0x2aabaecb67c869eaa93e59b942940a936390f39fe642c602dff254469e057c22));
        vk.gamma_abc[21] = Pairing.G1Point(uint256(0x2cb98c2f267a3d06422d7f70fa4eeb0840cbed4a4e27dc96c89403c1d74d76bc), uint256(0x12892288c9b0398deb3de341cef52f7abed5504ebd06df778f8a64756aab4cb6));
        vk.gamma_abc[22] = Pairing.G1Point(uint256(0x0a13ab1e8e6cbed481c54ebcc81b61524db3247f2a134630678703bd524195bd), uint256(0x04c94a3638191803e56a28eb13b0e7540d062748f5d64be7d38a5b8a1c1b1e5a));
        vk.gamma_abc[23] = Pairing.G1Point(uint256(0x135f934815e7e59084c2d95d86b0368fd5190bcf68700d761f6506beab49a756), uint256(0x167b278e5b138a1019929f35ecc1c2712540a9f379d63c53a0ba73a5e0f56789));
        vk.gamma_abc[24] = Pairing.G1Point(uint256(0x22a2a99ffa2ea22e870246baebcd9a05b40239d8b49bb14c9bd705e3efa2313d), uint256(0x1bc1cf2d1ab1d91c29450f06dbafa7a89b847c1aaad98ad3ad44c2defae52c71));
        vk.gamma_abc[25] = Pairing.G1Point(uint256(0x1003a88af6734bb5903140de9365054af685d81be7340171e6bc8e085ea6e0a5), uint256(0x218382e42eeae9a1d21a2c0736c05cc26982dc1fd2360d26795338be631165ed));
        vk.gamma_abc[26] = Pairing.G1Point(uint256(0x00db2c69eb5f1d1f87c1e2b0f515dc3b7db0bd065f6a351536f9b0da71638897), uint256(0x1e33bdaf4fad72d26b98a37708dde3af2119b27b4e9b95e6cff481f45c4d79e0));
        vk.gamma_abc[27] = Pairing.G1Point(uint256(0x1ac717f7868470b653f9a797ab0c39b3966e4d051c920cec90fb9cc27f8408d6), uint256(0x0a64b068ac59e449fcaba6fe0ea65601260cadbc48ac3a90ca359b98ac3e0d57));
        vk.gamma_abc[28] = Pairing.G1Point(uint256(0x1319fb4b33abd465043a69d172bffbdaf07bfd2a81f6e6b8e4cdfe61f4fc054d), uint256(0x26261a93af676ca61a2c360a427c265f9dce2cedbf2171c51b9021115fd7b069));
        vk.gamma_abc[29] = Pairing.G1Point(uint256(0x0dbee1ed4dfbcff42c5d1685d12021d0eab8e6e44c386b61f3573e314e64bcf0), uint256(0x254ecb409af897486bda2668868f3fa45985606f644f839c1bf4a633250ed8db));
        vk.gamma_abc[30] = Pairing.G1Point(uint256(0x1e661047a676272bfab280468da5db633a899e3f71c49d140f8ddd187acf446a), uint256(0x2d8cf57ca8f3dafe85b67acca0ca1041804a66b4fcd471536416580493be2aea));
        vk.gamma_abc[31] = Pairing.G1Point(uint256(0x1166dd65869f639b6b40f52338d5f0e8ebd6b83547f8abdf13040d3fcd7bce67), uint256(0x1b1c05dfac5e10866d3194e8546ed1b4e8c662ec74d7f16a2723ca18132bb964));
        vk.gamma_abc[32] = Pairing.G1Point(uint256(0x01d0a9e7fc5941036856e4e7c0e5fe23ffa919630fcc13f64c3604a14c603e3d), uint256(0x26b89e475d47cbb9dc2fd98e573d52fa1aa18a54717502a6ba1bc5b42c6f701d));
        vk.gamma_abc[33] = Pairing.G1Point(uint256(0x1f195cb463bec2890f03c688a375b9fd19d7967f4aaa302ca00a150cb5a363ab), uint256(0x2acf69cdd7f37943eccf03e93977b174974b8c77f8443d6ad4c90ba41f167bb4));
        vk.gamma_abc[34] = Pairing.G1Point(uint256(0x292e1696500947a018ea48ae814e4ec394bb762592cd8e1dbc974d12a0106b17), uint256(0x02e4947b3976546ef92305d7a134dcf37ead1c944ac4f5867096988c70e1c286));
        vk.gamma_abc[35] = Pairing.G1Point(uint256(0x12964ee4cc77e3627ac219d3c4191d16ee70dfc365aac8c9563d1df0a077676e), uint256(0x29105654292ab30a1e56252db37f4e5340099609679216f1d3467acc2165ec5e));
        vk.gamma_abc[36] = Pairing.G1Point(uint256(0x0f352d0cc814d8532aba76fca4b795b24358a1e77c60fab153162b53234a5267), uint256(0x2360f557594435919e37e3fb91c85e30c95eff45a101231175c61c8683e9997b));
        vk.gamma_abc[37] = Pairing.G1Point(uint256(0x2512fd430eb7255affe58c5d79034722ce34c962211390eb959ca5ddc2b594d8), uint256(0x0f5101d90545a91ab323a545224bdb834789eb6d37348c9f3647686b1e158d3e));
        vk.gamma_abc[38] = Pairing.G1Point(uint256(0x09a841d16048d6571c247205cb7cbb156f1202af514010bb40b44ad4c2e4cf1c), uint256(0x2b992b813ef922f739a091fa4566931838f6e353101d493d18b50e6b301a4f69));
        vk.gamma_abc[39] = Pairing.G1Point(uint256(0x1969688c61ba4406aa86ac35e48704d298b4dfd54c7d03593a837652a52b1f5d), uint256(0x2377203415133ea4392ae1fde0d4d89adb07189c35402739dfeb7f8113de6988));
        vk.gamma_abc[40] = Pairing.G1Point(uint256(0x0b93da78dc6cc27505b099b3466d704a5e984a072379e6d8c5d7b5a0f52b70da), uint256(0x064d2dc720903afef904e3c57972d1e4f1a7cbdaf63cc299c1509dde2d33680b));
        vk.gamma_abc[41] = Pairing.G1Point(uint256(0x08bf83756b27d562a6afd3e3858a989cd1fb3f2a6ad8c50376b4283f777b93a8), uint256(0x12b26b0bb7fad13c815b63761857e96ebe96a5949a2a01828a95d0191c1a3c84));
        vk.gamma_abc[42] = Pairing.G1Point(uint256(0x190cccaeaebccadd84b082b01a673de1286b03a9934a709244a26037dd0f10b0), uint256(0x2360330ce587cf1b4244c451093306f547bb27d110aa16f5f2686fbff5b67a03));
        vk.gamma_abc[43] = Pairing.G1Point(uint256(0x128aacbea259f5fb9b77b4c826049c3d053fa414871ced904968afb63f9b8087), uint256(0x053ead7f4ac32c5a07e1eb6eee017ed9d7de438e1f6df697effef24c3c931034));
        vk.gamma_abc[44] = Pairing.G1Point(uint256(0x064fdfdb736838c9b04a43b8ace9e0372f3367fb53acd305badbcd33b19796cb), uint256(0x30324ccedd1dbf797c4085ca9f245dd4b7740f4844cdec8db1da6814a306f54d));
        vk.gamma_abc[45] = Pairing.G1Point(uint256(0x0c903baf8123046babfd172e2e0b4637e7bd1441dcf9604e93afef6407faffa2), uint256(0x00f8354b3d42764b7d740e340dc552b3b03478bf2cec4fe9a6f8bfbd41e9f200));
        vk.gamma_abc[46] = Pairing.G1Point(uint256(0x12479ee8a7cebc35af96fd60a58c729a0dbec6cde3218dc42f716d573d953f5a), uint256(0x290b8e42b1a51feed512ba0f010ece268bc63805c6ce36f464fa80318df585ed));
        vk.gamma_abc[47] = Pairing.G1Point(uint256(0x2e42ffb55b14764a0c45e5d98dce33ff318c39374056e71b368d58799e55965e), uint256(0x13962133b638f47ea5022224401248cff62e41917068ce9adc8243220f0973d0));
        vk.gamma_abc[48] = Pairing.G1Point(uint256(0x28359bd6699b1537efe20aad1c1ea8afea814e8916c1da35de79cf87761aacdc), uint256(0x0790116a897cdc7201f235fd3028a8a608545fcad9b1a321dbf70c837a4ab3d8));
        vk.gamma_abc[49] = Pairing.G1Point(uint256(0x24c607f31e10e43ca7dcbe5c9c64c0bdb5ce99655778d2024d26cf720a5a1a65), uint256(0x29c02ec45bef45156195a4bf7c50ad3ab3246694d390b71a5bbfec35460134a6));
        vk.gamma_abc[50] = Pairing.G1Point(uint256(0x26562e324cb14386ad728192a55c6e3a355341a4866d4d036174582c6562c1ef), uint256(0x0be30d4274598571c08fda17f9687b0f9e2e200a74a9c816942cf06f3aae66b1));
        vk.gamma_abc[51] = Pairing.G1Point(uint256(0x0fa1eb32912ae8aa26ce8351a14c739637a98b5f82b1d1f553d88549b98a56d8), uint256(0x0c8ca4952c1deff7b9ea4206e3d63437d805903116c8ce978102fdff1cbad1b8));
        vk.gamma_abc[52] = Pairing.G1Point(uint256(0x1e940341c8750ccdda62e565120b16953b61994a3b5ced706e8eab8257f8be77), uint256(0x16c7954f014126b72d833fa513a7335caf8e9721ddc9bbb63b8f2dfce34b770f));
        vk.gamma_abc[53] = Pairing.G1Point(uint256(0x018106aebb1da2f3009a703dc56395c3025fcd5bb2ea9fb9f577930d11b549b1), uint256(0x2473942bd7d079924d469aaf94540d3095cda5d107fe25411da9b840b94c0854));
        vk.gamma_abc[54] = Pairing.G1Point(uint256(0x28874a7424dbc6a8941454712b68c042fb55af176e7006fe753ee7e4be0709f2), uint256(0x18fdaa163734844a4a1da225b958a2734ba88e87ecfaec6a97755a1d32f05c66));
        vk.gamma_abc[55] = Pairing.G1Point(uint256(0x1065b258587173cafdf3d973cdc1bb6314518418af68d0c96dc3a619682b8500), uint256(0x2735c34bcebee773120f6f3b9431a37621ac3141fb4b12c5a0503b3a0cba4dc5));
        vk.gamma_abc[56] = Pairing.G1Point(uint256(0x1b82938a117707ac26db5d27f7f401c6c926597ca39ceb38d3f73a1bee49b914), uint256(0x1f50b5374cec8fc36545fb5642507c449178ae5a553e3ed04f38351612bca4a9));
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.alpha), vk.beta)) return 1;
        return 0;
    }
    function verifyTx(
            Proof memory proof, uint[56] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](56);
        
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
