import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { encodeFunctionData } from "viem";

import { network } from "hardhat";

describe("MyERC1155Tokens", async function () {
    const { viem } = await network.create();
    const publicClient = await viem.getPublicClient();

    const walletClients = await viem.getWalletClients();
    const [owner, alice, bob, trustedForwarder] = walletClients;  

    it("Should call setApprovalForAll By Permit ", async function () {
        const tokens = await viem.deployContract("MyERC1155Tokens", [trustedForwarder.account.address]);

        let nonce = await tokens.read.nonces([alice.account.address]);

        const domain = {
            name: "ThreeTokens",
            version: "1",
            chainId: publicClient.chain.id,
            verifyingContract: tokens.address,
        };     

        const types = {
            Permit: [
                { name: "owner", type: "address" },
                { name: "operator", type: "address" },
                { name: "approved", type: "bool" },
                { name: "nonce", type: "uint256" },
                { name: "deadline", type: "uint256" },
            ],
        };

        const deadline = Math.floor(Date.now() / 1000) + 24 * 60 * 60;       

        const message = {
            owner: alice.account.address,
            operator: bob.account.address,
            approved: true,
            nonce,
            deadline
        };
        
        const signature = await alice.signTypedData({
            domain,
            types,
            message,
            primaryType: "Permit",
        });
        
        await tokens.write.permit([
            alice.account.address, 
            bob.account.address, 
            true, 
            BigInt(deadline), 
            parseInt(signature.slice(130, 132), 16), 
            `0x${signature.slice(2, 66)}`, 
            `0x${signature.slice(66, 130)}`
        ]);
    });

    it("Should safeTransferFrom via ERC-2771 meta-transaction", async function () {
        const forwarder = await viem.deployContract("ERC2771TrustedForwarder");
        const tokens = await viem.deployContract("MyERC1155Tokens", [
            forwarder.address,
        ]);

        const transferAmount = 100n;
        const tokenId = 0n;
        const ownerAddress = owner.account.address;
        const aliceAddress = alice.account.address;

        const balanceBeforeOwner = await tokens.read.balanceOf([
            ownerAddress,
            tokenId,
        ]);
        const balanceBeforeAlice = await tokens.read.balanceOf([
            aliceAddress,
            tokenId,
        ]);

        const transferData = encodeFunctionData({
            abi: tokens.abi,
            functionName: "safeTransferFrom",
            args: [ownerAddress, aliceAddress, tokenId, transferAmount, "0x"],
        });

        const nonce = await forwarder.read.nonces([ownerAddress]);
        const deadline = BigInt(Math.floor(Date.now() / 1000) + 24 * 60 * 60);

        const metaTx = {
            from: ownerAddress,
            to: tokens.address,
            value: 0n,
            gas: 1_000_000n,
            nonce,
            data: transferData,
            deadline,
        };

        const forwarderDomain = {
            name: "ERC2771TrustedForwarder",
            version: "1",
            chainId: publicClient.chain.id,
            verifyingContract: forwarder.address,
        };

        const metaTxTypes = {
            MetaTransaction: [
                { name: "from", type: "address" },
                { name: "to", type: "address" },
                { name: "value", type: "uint256" },
                { name: "gas", type: "uint256" },
                { name: "nonce", type: "uint256" },
                { name: "data", type: "bytes" },
                { name: "deadline", type: "uint256" },
            ],
        };

        const signature = await owner.signTypedData({
            domain: forwarderDomain,
            types: metaTxTypes,
            primaryType: "MetaTransaction",
            message: metaTx,
        });

        // Релейер (bob) платит газ; подписант — owner.
        await forwarder.write.execute([metaTx, signature], {
            account: bob.account,
        });

        assert.equal(
            await tokens.read.balanceOf([ownerAddress, tokenId]),
            balanceBeforeOwner - transferAmount,
        );
        assert.equal(
            await tokens.read.balanceOf([aliceAddress, tokenId]),
            balanceBeforeAlice + transferAmount,
        );
        assert.equal(await forwarder.read.nonces([ownerAddress]), 1n);
    });
});
