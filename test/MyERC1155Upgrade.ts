import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { encodeFunctionData, getContract } from "viem";

import { network } from "hardhat";

describe("MyERC1155Upgrade", async function () {
    const { viem } = await network.create();
    const [owner, alice] = await viem.getWalletClients();

    async function deployProxy(trustedForwarder: `0x${string}`) {
        const impl = await viem.deployContract("MyERC1155Tokens");
        const initData = encodeFunctionData({
            abi: impl.abi,
            functionName: "initialize",
            args: [trustedForwarder],
        });
        const proxy = await viem.deployContract(
            "ERC1967Proxy", 
            [impl.address, initData], 
//            { account: owner.account }
        );
        const tokens = await viem.getContractAt(
            "MyERC1155Tokens",
            proxy.address,
        );
        return { impl, proxy, tokens };
    }

    it("Should deploy proxy, initialize, and upgrade to V2", async function () {
        const forwarder = await viem.deployContract("ERC2771TrustedForwarder");
        const { proxy, tokens } = await deployProxy(forwarder.address);

        assert.equal(await tokens.read.version(), 1n);
        assert.equal(
            await tokens.read.balanceOf([owner.account.address, 0n]),
            1000n,
        );

        const implV2 = await viem.deployContract("MyERC1155TokensV2");

        await tokens.write.upgradeToAndCall([implV2.address, "0x"], {
            account: owner.account,
        });

        const proxyContract = await getContract({
            address: proxy.address,
            abi: proxy.abi,
            client: await viem.getPublicClient(),
        });
        assert.equal(
            (await proxyContract.read.implementation()).toLowerCase(),
            implV2.address.toLowerCase(),
        );
        assert.equal(await tokens.read.version(), 2n);

        await tokens.write.safeTransferFrom(
            [owner.account.address, alice.account.address, 0n, 50n, "0x"],
            { account: owner.account },
        );
        assert.equal(
            await tokens.read.balanceOf([owner.account.address, 0n]),
            950n,
        );
        assert.equal(
            await tokens.read.balanceOf([alice.account.address, 0n]),
            50n,
        );
    });
});
