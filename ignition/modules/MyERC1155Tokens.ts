import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("MyERC1155TokensModule", (m) => {
    const trustedForwarder = m.getParameter(
        "trustedForwarder",
        "0x0000000000000000000000000000000000000000",
    );

    const implementation = m.contract("MyERC1155Tokens");
    const initData = m.encodeFunctionCall(implementation, "initialize", [
        trustedForwarder,
    ]);
    const proxy = m.contract("ERC1967Proxy", [implementation, initData]);

    return { implementation, proxy };
});
