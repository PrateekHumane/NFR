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

contract MergeZKP {
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
        vk.alpha = Pairing.G1Point(uint256(0x08316e7e85dd27c37cd89478deb50bf843cd6d07a6ac7ae73742ec0c20e046bb), uint256(0x2098f57c08a9faa473206685e5ae0b137a6a128be45db60eae79632c99c9eff1));
        vk.beta = Pairing.G2Point([uint256(0x0e7c571ffc4b6ae2b2b7bfcd051b97b4c0d6388e32fecab7a65994d289187258), uint256(0x1444b9a5d33e453d0c9a2c65f0fcbe352e8c449063a21846191dbbc9d215712c)], [uint256(0x136da2ca4b7e1c5d17a04f37ab8d727e1bedb5cf7132d23f6f3098cae667400d), uint256(0x031dab2c72f86785e350bd2dcfee2463cbff896256d4c157fb3f7fc8d263fb62)]);
        vk.gamma = Pairing.G2Point([uint256(0x1c5badb7a801e2e9cc2bba7a707686fe90aaa3380b45510a838a7a5debf428da), uint256(0x0b7ffe845e37a8cc455438f35790b0ee13b68750f22d675451788f23c377d402)], [uint256(0x05eeb02c5e05d56dd6cf82630d427553ca2af9ea609460ec5ca4b81efb31c35c), uint256(0x2c1226e9208b5893560db4488974602c9dcff56e5c48929e2ff7e1b9017374d2)]);
        vk.delta = Pairing.G2Point([uint256(0x2cd740974266fbd8e6fcd51b43eb6bcc75a3b8cfe93f9d1f649354f63d3e8bea), uint256(0x299657cd6e64e5876ce11f783a0187200f51864087af7bb769b1867d183a6579)], [uint256(0x0042b6b5d843bc8115dbb85309c49a2ba506102c88ce68618144fb54ff87ddbb), uint256(0x2737014d1709109b0bb8fae41c4cfe090938ce2e6d35e125400a4750c016d37d)]);
        vk.gamma_abc = new Pairing.G1Point[](32);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x189ac3ae8ae346cc94faf64de549c573d830933f6a45f941d7364de02e84bde9), uint256(0x066297ee0118aec36ef9ef5b09972ad07d261dc31f58164fc149da4574576b95));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x2b2fa5c0badfdb62a2dc5b05d5879ecb553d7d85c5c92a3a148b0bc9d0ec1845), uint256(0x29ee0cabeb3bce664f6d97ec9b78df2289694f1cf1d47524b7c2b8b55d75440f));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x2bafbe49c6c98e456a008a8ef3c39b2ca269cbbbfd5ac67b5811ba4fa522e630), uint256(0x2ac69737f15ea7fcd5d7094cc1c65a512247efe9ea86fc435592bbf57647a7a4));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x08dc70b56428f6b356aa33add2aa54b29bb100334ebb4711d25c659f47cf54b1), uint256(0x18b088def4503e2bc1d4a354ca2e731913b650e4facf07893a3cbe6ee0078ebb));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x2a7651175370b10f16590e1416ad5e3cdb1c75066bccb81e23d2b0eae75a71a1), uint256(0x1f8c00fd94d7703f8080d882407294bc9ddb04c77ba35acb3930e89e011d2f42));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x0342ded552ee446c42e3a7e3cb6ce1140a7b2a52e9e0e7d095726b6830e86324), uint256(0x2b9be265129b4b6ed1098de89dbb968a959f0ca29d5db927c6ebf47f0a379287));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x132fc704876abaf46bfbbd1414997fbc5dd375ec6404300cba3cb592d5043ea7), uint256(0x114811f0380c0491895e1685e4bcc84947c98146af9d45894ee5842ba6b6c2b9));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x1e2965da3a25829015eb18e04777319c68ecfbd3e9d22bd2ed6425aa50b0f7c0), uint256(0x147c50dd3195482d081702dc1a2e5551190e05bd0ff862a1f2ee551eeba47cdc));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x28a4a719d387ab98d12e0d07662bf17bc7202855a4138867118654ba8fa55b9d), uint256(0x11feb463b3801f46c697c15b8767b09d4964ec31041ccd88599a55441a80f3ca));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x0820aded374924dc6d4614d3fff8814336be721737d4e3ed8870c765b3859065), uint256(0x13ec5598986a665c7d2bb442f03e3cf4158845499908bfc1c5d32042cf0ff654));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x13aff777f7a9b837fd06becfffd13f1f2863edc95155da1af389b1dae5e37181), uint256(0x293519b4ae3178c9e8c27374a21552af278dbeb302a7329a045eef32903bd451));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x1adca13c58ea21d25f20d307ce3a9373ec6b1c62b0e96430665304027954e3ff), uint256(0x23a9b7b880acbbb3b871a2fd1ce976cf9e958e6d3086a5360dbef64dcc1c1a84));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x065ffcc80bed7ae0bd84db6da5a6b4aa06aa1084660a457bb2e50d3a2bb649ac), uint256(0x040c976749533f3041bbbdc64a7732feaecc48be52a90da2db932abf0c1cfb9e));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x2c576cd7b330ec6fd50dae0b5f4e927a14d081357e4184fad4145c4810be5072), uint256(0x03861f03942113d73886667a17e65168b481c55164917e0cbe8d7cac530a87ae));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x28ff36f78987a90f6d75b39c53403d0567fbf43b834564bb1d121af7525e4fc2), uint256(0x0f9c32a47e11e2ab3c22d5422f6270ea51a82aa8ce65069da70e2c790a477a45));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x2b569f8d3b992056136d5e164c0bc0eade26355cbf293aaba3399fd543dfd6b5), uint256(0x09e973f1de523c8e78c22829eedba52119977fa4cf85a28237341f2cde8e1946));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x23ba70b04ece41318d16d0f343fb8472550bedd838de0458aaf4dea8bc625a5f), uint256(0x1a09fcf825edbd78567147139de2cd0184fe3e65e7abaf114a6a58af18b440aa));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x00f84a7ceb8d3397c44a19eaf5bc126648f030ba9a34432b216e558267d463c9), uint256(0x09831b875d68b1ac7214e8a270e928ca71c71d9b745f5e488595e4b034392d04));
        vk.gamma_abc[18] = Pairing.G1Point(uint256(0x2d11491c84cd4bfaa9090f5b80115976659ba9ecbd189b110ee5c7b44158cd00), uint256(0x12dcc02f02cc5b4003224f35c272ea49c0c905249c7fec94d9a1e63d860f44c5));
        vk.gamma_abc[19] = Pairing.G1Point(uint256(0x03c98d2b8bca5783da047bdd6436b1f10c67023449503e8dbcbb13f2ab2fd689), uint256(0x0b74500e94baed7f4697131f07572c9756af6cd803dea835a86ab582eaec95df));
        vk.gamma_abc[20] = Pairing.G1Point(uint256(0x21b9127a40a105779440354ad3af116ef647c3857a66b7ada8df722bbe637be4), uint256(0x2a9c91bbe2e8fe23e06506572926aa92e331854004b670b7fdd95a1104bd6caa));
        vk.gamma_abc[21] = Pairing.G1Point(uint256(0x0a7632dd89cac4e49f9bc60c000bad92ec10621ae6bc67dc14b6a16449aa57dc), uint256(0x3019c8042679391084204c1d35cd9247dbb066f282facae947d9b32ff5448bbf));
        vk.gamma_abc[22] = Pairing.G1Point(uint256(0x0c536f5f197567ded49140a715694ca24214743dc6e724a5e2af32d51ef404f8), uint256(0x04fa50aac811aa839ef2429e0abf02d61c3e85434926bd0ab082deeec4bd3158));
        vk.gamma_abc[23] = Pairing.G1Point(uint256(0x013576e4ee879c9c4592c1d050e62a3855d29dc17be6de8ce9f7d6fa3c8b12cc), uint256(0x2f4949964bdb192b045ee66f13addf0d40e3c77aa7f715e5a412063aed987ee3));
        vk.gamma_abc[24] = Pairing.G1Point(uint256(0x1331a3981e1e0269ea4e151ff59db91a508be83fbeae797d14e06112e1bafd47), uint256(0x1d8d23c30286097337f16dacc5f6f49e842a4132e6c217003c30839571a1177e));
        vk.gamma_abc[25] = Pairing.G1Point(uint256(0x154c990dd46fcb339e626e674c20990f4797244e0ddc4d2a9226a238baa4f5f0), uint256(0x006f9be0e42547fc4520fd9a63ecd3241ea7f71b2482e5eb810ce8ea11221d99));
        vk.gamma_abc[26] = Pairing.G1Point(uint256(0x1a3761befc154110cdb5b1a516023e3d6c0408b9639746e2a99f98ac3b35dd79), uint256(0x12c5e92bd395fdd57c7d89ef9cb9297f3afa73138ebef8a9126b7c1e8974ce04));
        vk.gamma_abc[27] = Pairing.G1Point(uint256(0x0cf19eb7bdb14b66f7da123f206786c9458a616afab5ed46fc2cf2e130209114), uint256(0x2ece12f7071d0d7bd4f568235a41d123745cc37a37d5dc5fc941d70ae008dd20));
        vk.gamma_abc[28] = Pairing.G1Point(uint256(0x093bc031f8add10fe7c23cc6ada5c6ebbfbfaaff5e9f18ce280138861316d789), uint256(0x01b9ff06019819f9972d3b4e8d5b04a19cb51fb2d1c8120a101233430ec840c9));
        vk.gamma_abc[29] = Pairing.G1Point(uint256(0x06c38b1682cd59e17ea38085ebef57064cf43e7b313f019b43f7a08826fa4f8a), uint256(0x206988fcc4dfb0e6bb9737b35a83f310f1f5c057447d4f69c2760621dd230d7d));
        vk.gamma_abc[30] = Pairing.G1Point(uint256(0x12db77a8de5a942263644730486f01c1b6340536e569c0142f6c4b52263e9e4a), uint256(0x11497d17acc97d08e82fa7eed58c43b3400203f2779fe04de38b403e2a4d3edc));
        vk.gamma_abc[31] = Pairing.G1Point(uint256(0x0dd62498c8632f61a26ea3d93c7a671a2fd04701483403af88354c76aedf40d8), uint256(0x289d620e4c5cb6111340f1226a60b8aa06a01aa4ceb26449afe79dde29b90973));
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
            Proof memory proof, uint[31] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](31);
        
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
