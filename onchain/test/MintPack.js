const NFR = artifacts.require("NFR");

contract("testing mint packs", async accounts => {
    it("mint work?", async () => {
        const instance = await NFR.deployed();
        const roots = await instance.mintPack.call(42,43,44);
        console.log(roots.map(root => root.toString('hex')));
    });

    // it("test max minting", async () => {
    //     const instance = await NFR.deployed();
    //     for (let i = 0; i < 10; i++) {
    //         let roots = await instance.mintPack.call(42, 43, 44);
    //         console.log(roots.map(root => root.toString('hex')));
    //         await instance.mintPack(42,43,44);
    //         console.log((await instance.packsMinted.call()).toString());
    //     }
    //
    //     console.log((await instance.cardCopiesHashed.call()).toString());
    //     console.log(await instance.gameStarted.call());
    //     console.log((await instance.baseCardCopyCounts.call(0)).toString());
    //     console.log((await instance.packsMinted.call()).toString());
    // });
});
