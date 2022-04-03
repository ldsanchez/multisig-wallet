import { Button, Card, DatePicker, Divider, Input, Progress, Slider, Spin, Switch } from "antd";
import React, { useState } from "react";
import { utils } from "ethers";
import { SyncOutlined } from "@ant-design/icons";

import { Address, Balance, Events } from "../components";
import CreateMultisigWalletModal from "../components/CreateMultisigWalletModal";

export default function ExampleUI({
  price,
  selectedChainId,
  mainnetProvider,
  address,
  tx,
  writeContracts,
  contractName,
  isCreateModalVisible,
  setIsCreateModalVisible,
}) {
  return (
    <div>
      <CreateMultisigWalletModal
        price={price}
        selectedChainId={selectedChainId}
        mainnetProvider={mainnetProvider}
        address={address}
        tx={tx}
        writeContracts={writeContracts}
        contractName={"MultisigWalletFactory"}
        isCreateModalVisible={isCreateModalVisible}
        setIsCreateModalVisible={setIsCreateModalVisible}
      />
    </div>
  );
}
